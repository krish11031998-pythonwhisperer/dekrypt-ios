//
//  WatchlistViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 15/05/2024.
//

import UIKit
import KKit
import Combine
import DekryptUI
import DekryptService

class WatchlistViewController:TabViewController {
    
    override class var navName: String { "Watchlist" }
    
    override class var iconName: UIImage.Catalogue { .heart }

    private let viewModel: WatchlistViewModel = .init(tickerService: TickerService.shared)
    private var bag: Set<AnyCancellable> = .init()
    
    private lazy var collectionView: UICollectionView = .init(frame: .init(), collectionViewLayout: .init())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bind()
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
    }
    
    private func setupNavBar() {
        standardNavBar(leftBarButton: .init(view: "Watchlist".styled(font: CustomFonts.semibold, color: .textColor, size: 24).generateLabel))
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.sections
            .withUnretained(self)
            .sinkReceive { (vc, sections) in
                vc.collectionView.reloadWithDynamicSection(sections: sections)
            }
            .store(in: &bag)
        
        output.navigation
            .withUnretained(self)
            .sinkReceive { (vc, nav) in
                switch nav {
                case .toTicker(let ticker):
                    vc.pushTo(target: TickerDetailView(ticker: ticker.ticker, tickerName: ticker.name))
                }
            }
            .store(in: &bag)
    }
}
