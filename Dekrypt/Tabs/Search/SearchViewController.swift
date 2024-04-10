//
//  SearchViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 08/04/2024.
//

import DekryptUI
import DekryptService
import UIKit
import Combine

class SearchViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
    private lazy var header: SearchHeader = .init(placeHolder: "Explore coins...", header: "Search", onSearch: viewModel.searchParam)
    private let viewModel: SearchViewModel
    private var bag: Set<AnyCancellable> = .init()
    
    init(searchService: TickerServiceInterface = TickerService.shared, lunarService: LunarCrushServiceInterface = LunarCrushService.shared) {
        self.viewModel = .init(searchService: searchService, lunarService: lunarService)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        hideNavbar()
        setupView()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.contentInset.top = header.frame.height + .standardColumnSpacing
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.showsVerticalScrollIndicator = false
        
        let headerContainer = UIView()
        headerContainer.addSubview(header)
        header
            .pinTopAnchorTo(constant: .safeAreaInsets.top)
            .pinHorizontalAnchorsTo(constant: 0)
            .pinBottomAnchorTo(constant: 0)
        headerContainer.backgroundColor = .surfaceBackground
        
        view.addSubview(headerContainer)
        headerContainer
            .pinHorizontalAnchorsTo(constant: 0)
            .pinTopAnchorTo(constant: 0)
    }
    
    internal override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavbar()
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.section
            .withUnretained(self)
            .sinkReceive { (vc, section) in
                vc.collectionView.reloadWithDynamicSection(sections: section)
            }
            .store(in: &bag)
        
        viewModel.navigation
            .withUnretained(self)
            .sinkReceive { (vc, navigation) in
                switch navigation {
                case .toNews(let news):
                    vc.pushTo(target: NewsDetailView(news: news))
                case .toTicker(let ticker, let name):
                    vc.pushTo(target: TickerDetailView(ticker: ticker, tickerName: name))
                }
            }
            .store(in: &bag)
    }
    
}
