//
//  TickerDetailView.swift
//  DekryptUI_Example
//
//  Created by Krishna Venkatramani on 21/02/2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import KKit
import Combine
import DekryptUI
import DekryptService
import UIKit

public class TickerDetailView: UIViewController {
    
    private lazy var collectionView: UICollectionView =  {
        let collection: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
        collection.backgroundColor = .surfaceBackground
        return collection
    }()
    private let viewModel: TickerDetailViewModel
    private var bag: Set<AnyCancellable> = .init()
    private lazy var refreshControl: UIRefreshControl = .init()
    private lazy var addFavorites: UIBarButtonItem = {
        NavbarButton.navbarButton(img: .local(img: .Catalogue.heartOutline.image), highlightImg: .local(img: .Catalogue.heart.image))
    }()
    private lazy var addHabit: UIBarButtonItem = {
        NavbarButton.navbarButton(img: .local(img: .Catalogue.trendingUp.image))
    }()
    
    
    init(tickerService: TickerServiceInterface, eventService: EventServiceInterface, ticker: String, tickerName: String) {
        self.viewModel = .init(tickerService: tickerService, eventService: eventService, ticker: ticker, tickerName: tickerName)
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(ticker: String, tickerName: String) {
        self.init(tickerService: TickerService.shared, eventService: EventService.shared, ticker: ticker, tickerName: tickerName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bind()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    private func setupNavBar() {
        showNavbar()
        setupTransparentNavBar(color: .surfaceBackground, scrollColor: .surfaceBackground)
//        if let isPro = AppStorage.shared.user?.isPro, isPro {
//            navigationItem.rightBarButtonItems = [addHabit, addFavorites]
//        }
//        else {
//            navigationItem.rightBarButtonItems = [addFavorites]
//        }
//        
        if AppStorage.shared.user != nil {
            navigationItem.rightBarButtonItems = [addFavorites]
        }
        
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.refreshControl = refreshControl
        standardNavBar()
        collectionView.showsVerticalScrollIndicator = false
        startLoadingAnimation()
    }
    
    
    private func bind() {
        
        refreshControl
            .publisher(for: .valueChanged)
            .withUnretained(self)
            .sinkReceive { (vc, _) in
                vc.viewModel.refresh()
            }
            .store(in: &bag)
        
        let addFavorites = addFavorites
            .tapPublisher
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()

        
        let addHabit = addHabit
            .tapPublisher
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()

        
        let output = viewModel.transform(input: .init(addFavoritePublisher: addFavorites, addHabitPublisher: addHabit))
        
        output.section
            .withUnretained(self)
            .sinkReceive { (vc, section) in
                vc.endLoadingAnimation {
                    vc.collectionView.reloadWithDynamicSection(sections: section)
                }
                
                if vc.refreshControl.isRefreshing {
                    vc.refreshControl.endRefreshing()
                }
            }
            .store(in: &bag)
        
        AppStorage.shared.userPublisher
            .withUnretained(self)
            .sinkReceive { (vc, user) in
                guard let user else {
//                    if vc.navigationItem.rightBarButtonItems?.first === vc.addHabit {
//                        vc.navigationItem.rightBarButtonItems?.removeFirst()
//                    }
                    return
                }
//                if user.isPro, vc.navigationItem.rightBarButtonItems?.first !== vc.addHabit {
//                    vc.navigationItem.rightBarButtonItems?.insert(vc.addHabit, at: 0)
//                }
                
                if let watching = user.watching, watching.contains(vc.viewModel.ticker), vc.addFavorites.navBarButton?.isSelected != true  {
                    vc.addFavorites.navBarButton?.isSelected = true
                }
            }
            .store(in: &bag)
        
        output.navigation
            .withUnretained(self)
            .sinkReceive { (vc, navigation) in
                let viewController: UIViewController
                switch navigation {
                case .toNews(let news):
                    viewController = NewsDetailView(news: news)
                    vc.pushTo(target: viewController)
                case .moreNews(let preloaded):
                    viewController = NewsFeedViewController(newsService: NewsService.shared, includeSegmentControl: false, type: .preloaded(preloaded))
                    vc.pushTo(target: viewController)
                case .toEvent(let event):
                    viewController = EventDetailView(event: event)
                    vc.pushTo(target: viewController)
                case .toHabit:
                    viewController = TickerHabitBuilder()
                    vc.pushTo(target: viewController)
                case .videos(let videos, let videoToScrollTo):
                    viewController = VideoFeedViewController(videoModel: videos, videoToScrollTo: videoToScrollTo)
                    vc.pushTo(target: viewController)
                case .showAlertForOnboarding:
                    vc.presentErrorToast(error: "You have to sign in.")
                case .toNewsWithDate(let dateString):
                    vc.pushTo(target: TickerNewsFeedViewController(ticker: vc.viewModel.ticker, date: dateString, newsService: NewsService.shared))
                case .toSentimentDetail(let sentimentForTicker):
                    vc.pushTo(target: SentimentDetailViewController(model: sentimentForTicker, ticker: vc.viewModel.ticker))
                }
            }
            .store(in: &bag)
        
        output.addedFavorite
            .withUnretained(self)
            .sinkReceive { (vc, user) in
//                vc.addFavorites.navBarButton?.isSelected = state
                AppStorage.shared.user = user
            }
            .store(in: &bag)
        
        output.errorMessage
            .compactMap({ $0 })
            .withUnretained(self)
            .sinkReceive { (vc, errMsg) in
                vc.presentErrorToast(error: errMsg) {
                    vc.dismiss(animated: true)
                }
            }
            .store(in: &bag)
    }
    
}
