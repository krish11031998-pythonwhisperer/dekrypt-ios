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

public class HomeViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        .init(frame: .zero, collectionViewLayout: .init())
    }()
    private let viewModel: HomeViewModel
    private var bag: Set<AnyCancellable> = .init()
    private lazy var headerView: HeaderView = { .init() }()
    private let headerViewAnimator: UIViewPropertyAnimator = { .init(duration: 0.3, curve: .easeIn) }()
    
    public init(socialService: SocialHighlightServiceInterface = StubSocialHighlightService(), 
                videoService: VideoServiceInterface = StubVideoService()) {
        self.viewModel = .init(socialService: socialService, videoService: videoService)
        super.init(nibName: nil, bundle: nil)
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
        hideNavbar()
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.backgroundColor = .surfaceBackground
        collectionView.showsVerticalScrollIndicator = false
//        collectionView.contentInsetAdjustmentBehavior = .never
        setupHeader()
    }
    
    private func setupHeader() {
        let headerContainer = UIView()
        headerContainer.backgroundColor = .surfaceBackground
        
        let headerView = HeaderView()
        headerView.configure(with: .init(name: "Welcome to Dekrypt"))
        headerContainer.addSubview(headerView)
        headerView
            .pinTopAnchorTo(constant: navBarHeight)
            .pinHorizontalAnchorsTo(constant: 0)
            .pinBottomAnchorTo(constant: 0)
        
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
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sections in
                guard let self else { return }
                self.collectionView.reloadWithDynamicSection(sections: sections)
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
                    vc.pushTo(target: NewsFeedViewController(newsService: NewsService.shared, preloadedNews: news))
                case .toTickerDetail(let detail):
                    vc.pushTo(target: TickerDetailView(tickerService: TickerService.shared, eventService: EventService.shared, ticker: detail.ticker, tickerName: detail.name))
                case .toVideo(let videoModel):
                    vc.pushTo(target: YoutubeViewController(videoModel: videoModel), asSheet: true)
                }
            }
            .store(in: &bag)
        
        // Collection Scroll
        
        collectionView.publisher(for: \.contentOffset)
            .map { [weak self] in
                guard let self, $0.y <= 0 else { return -1 }
                let topInset = collectionView.contentInset.top + self.navBarHeight
                let yOff = abs($0.y)
                let percent = (yOff/topInset)
                let normalized = min(max(percent, 0), 1.0)
                return 1 - normalized
            }
            .filter({ $0 != -1 })
            .sinkReceive { [weak self] fraction in
                self?.headerViewAnimator.fractionComplete = fraction
            }
            .store(in: &bag)
            
    }
    
    
    deinit {
        headerViewAnimator.stopAnimation(true)
    }
    
}
