//
//  WatchlistViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 15/05/2024.
//

import UIKit
import SwiftUI
import KKit
import Combine
import DekryptUI
import DekryptService

class WatchlistViewController:TabViewController {
    
    override class var navName: String { "Watchlist" }
    
    override class var iconName: UIImage.Catalogue { .heart }

    private var filterContainer: UIView!
    @Published private var selectedFilter: (WatchlistViewModel.Section) = .tickers
    private let viewModel: WatchlistViewModel = .init(tickerService: TickerService.shared)
    private var bag: Set<AnyCancellable> = .init()
    private var emptyStateView: UIView?
    
    private lazy var collectionView: UICollectionView = .init(frame: .init(), collectionViewLayout: .init())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.contentInset.top = filterContainer.frame.maxY - view.safeAreaInsets.top
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        setupHeader()
    }
    
    private func setupHeader() {
        let filterView = FilterView<WatchlistViewModel.Section>(selectedCase: WatchlistViewModel.Section.tickers) { [weak self] section in
            self?.selectedFilter = section
        }
        let vc = UIHostingController(rootView: filterView)
        filterContainer = UIView()
        filterContainer.backgroundColor = .surfaceBackground
        filterContainer.addSubview(vc.view)
        vc.view.fillSuperview(inset: .init(top: 20, left: .appHorizontalPadding, bottom: .appVerticalPadding.half, right: .appHorizontalPadding))

        view.addSubview(filterContainer)
        filterContainer
            .pinTopAnchorTo(constant: navBarHeight)
            .pinHorizontalAnchorsTo(constant: .zero)
    }
    
    private func bind() {
        let output = viewModel.transform(input: .init(selectedTab: $selectedFilter.setFailureType(to: Never.self).eraseToAnyPublisher()))
        
        output.sections
            .withUnretained(self)
            .sinkReceive { (vc, watchlistResult) in
                switch watchlistResult {
                case .noTickers(let section):
                    vc.collectionView.reloadWithDynamicSection(sections: [section]) {
                        vc.addEmptyWatchlist(state: .noTickers)
                    }
                case .noUserSession(let section):
                    vc.collectionView.reloadWithDynamicSection(sections: [section]) {
                        vc.addEmptyWatchlist(state: .noUser)
                    }
                case .ticker(let section):
                    if vc.emptyStateView != nil {
                        vc.emptyStateView?.removeFromSuperview()
                        vc.emptyStateView = nil
                    }
                    vc.collectionView.reloadWithDynamicSection(sections: [section])
                }
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
    
    private func afterCollectionLoad() {
        guard let reachedEnd = collectionView.reachedEnd else { return }
        
        reachedEnd
            .removeDuplicates()
            .combineLatest($selectedFilter.setFailureType(to: Never.self).eraseToAnyPublisher())
            .filter({ $0 && $1 == .tickers })
            .withUnretained(self)
            .sinkReceive { (vc, state) in
                print("(DEBUG) state: \(state) with page: \(vc.viewModel.nextPage.value + 1)")
                vc.viewModel.nextPage.send(vc.viewModel.nextPage.value + 1)
            }
            .store(in: &bag)
    }
    
    private func addEmptyWatchlist(state: EmptyWatchlistStateView.State) {
        let emptyView = EmptyWatchlistStateView(state: state)
        
        if self.emptyStateView != nil {
            self.emptyStateView?.removeFromSuperview()
            self.emptyStateView = nil
        }
        
        self.emptyStateView = addSwiftUIView(emptyView)
        
        self.emptyStateView?
            .pinCenterXAnchorTo(constant: 0)
            .pinCenterYAnchorTo(constant: 0)
    }
}
