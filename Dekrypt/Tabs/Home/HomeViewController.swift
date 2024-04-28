//
//  HomeViewController.swift
//  DekryptUI
//
//  Created by Krishna Venkatramani on 21/01/2024.
//

import UIKit
import Combine
import KKit
import DekryptUI
import DekryptService

public class HomeViewController: UIViewController, TabViewController {
    
    private lazy var collectionView: UICollectionView = {
        .init(frame: .zero, collectionViewLayout: .init())
    }()
    private let viewModel: HomeViewModel
    private var bag: Set<AnyCancellable> = .init()
    private lazy var headerView: HeaderView = { .init() }()
    private weak var headerViewTopConstraint: NSLayoutConstraint!
    private let headerViewAnimator: UIViewPropertyAnimator = { .init(duration: 0.3, curve: .easeIn) }()
    private(set) var initialLoad: PassthroughSubject<Void, Never> = .init()
    public init(socialService: SocialHighlightServiceInterface = StubSocialHighlightService(),
                videoService: VideoServiceInterface = StubVideoService()) {
        self.viewModel = .init(socialService: socialService, videoService: videoService)
        super.init(nibName: nil, bundle: nil)
    }
    private lazy var refreshControl: UIRefreshControl = .init()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bind()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerViewTopConstraint.constant = view.safeAreaInsets.top == 0 ? .appVerticalPadding : view.safeAreaInsets.top
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavbar()
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.backgroundColor = .surfaceBackground
        collectionView.showsVerticalScrollIndicator = false
        collectionView.refreshControl = refreshControl
        setupHeader()
    }
    
    private func setupHeader() {
        let headerContainer = UIView()
        headerContainer.backgroundColor = .surfaceBackground
        
        let headerView = HeaderView()
        headerView.configure(with: .init(name: "Welcome to Dekrypt"))
        headerContainer.addSubview(headerView)
        headerView
            .pinHorizontalAnchorsTo(constant: 0)
            .pinBottomAnchorTo(constant: 0)
        headerViewTopConstraint = headerView.topAnchor.constraint(equalTo: headerContainer.topAnchor)
        headerViewTopConstraint.isActive = true
        
        view.addSubview(headerContainer)
        headerContainer
            .pinTopAnchorTo(constant: 0)
            .pinHorizontalAnchorsTo(constant: 0)
        
        headerViewAnimator.addAnimations { [weak headerContainer] in
            guard let headerContainer else { return }
            headerContainer.transform = .init(translationX: 0, y: -headerContainer.compressedSize.height - .appVerticalPadding)
        }
        
        headerViewAnimator.pausesOnCompletion = true
        
        collectionView.contentInset.top = headerView.compressedSize.height
        
        startLoadingAnimation(centeralizeWithScreen: true)
    }
    
    private func bind() {
        
        refreshControl
            .publisher(for: .valueChanged)
            .sinkReceive { [weak self] value in
                self?.viewModel.refresh()
            }
            .store(in: &bag)
        
        let output = viewModel.transform()
        let sections = output.sections.share()
        
        sections
            .withUnretained(self)
            .sinkReceive({ (vc, sections) in
                vc.endLoadingAnimation {
                    vc.collectionView.reloadWithDynamicSection(sections: sections)
                }
                
                if vc.refreshControl.isRefreshing {
                    vc.refreshControl.endRefreshing()
                }
            })
            .store(in: &bag)
        
        sections
            .prefix(1)
            .withUnretained(self)
            .sinkReceive { (vc, _) in
                vc.initialLoad.send(())
            }
            .store(in: &bag)
        
        output.navigation
            .withUnretained(self)
            .sinkReceive { (vc, navigation) in
                switch navigation {
                case .toNews(let news):
                    vc.pushTo(target: NewsDetailView(news: news))
                case .toEvent(let event):
                    vc.pushTo(target: EventDetailView(event: event))
                case .toTickers(let tickers):
                    vc.pushTo(target: TickerViewController(model: .init(tickers: tickers)))
                case .toAllNews(let news):
                    vc.pushTo(target: NewsFeedViewController(newsService: NewsService.shared, type: .preloaded(.init(news: news))))
                case .toTickerDetail(let detail):
                    vc.pushTo(target: TickerDetailView(tickerService: TickerService.shared, eventService: EventService.shared, ticker: detail.ticker, tickerName: detail.name))
                case .toVideo(let videoModel):
                    vc.pushTo(target: YoutubeViewController(videoModel: videoModel), asSheet: true)
                case .toInsight(_):
                    print("(DEBUG) Clicked on insight")
                case .toAllInsights(let insights):
                    vc.pushTo(target: InsightViewController())
                }
            }
            .store(in: &bag)
    }
    
    
    deinit {
        headerViewAnimator.stopAnimation(true)
    }
    
    
    // MARK: - TabViewController
    
    var tabItem: MainTabModel { .home }
    
}
