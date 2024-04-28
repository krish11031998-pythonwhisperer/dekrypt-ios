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
        showNavbar()
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
        
        let output = viewModel.transform()
        
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
        
//        output.reloadFavorite
//            .withUnretained(self)
//            .sinkReceive { (vc, header) in
//                vc.collectionView.reloadItems(header.2, section: header.0.rawValue, index: header.1, alsoReload: header.3)
//            }
//            .store(in: &bag)
        
        output.navigation
            .withUnretained(self)
            .sinkReceive { (vc, navigation) in
                let viewController: UIViewController
                switch navigation {
                case .toNews(let news):
                    viewController = NewsDetailView(news: news)
                case .toEvent(let event):
                    viewController = EventDetailView(event: event)
                }
                vc.pushTo(target: viewController)
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
