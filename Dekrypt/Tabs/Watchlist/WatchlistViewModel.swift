//
//  WatchlistViewModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 15/05/2024.
//

import Combine
import DekryptService
import DekryptUI
import KKit
import UIKit

extension Array where Self.Element: Hashable {
    func uniqueValues() -> [Self.Element] {
        var newValues: [Self.Element] = []
        self.forEach { value in
            if !newValues.contains(value) {
                newValues.append(value)
            }
        }
        return newValues
    }
}

class WatchlistViewModel {
    
    
    enum Section: Int, FilterType {
        case tickers = 0
        case watchlist
        
        var name: String {
            switch self {
            case .tickers:
                return "Tickers"
            case .watchlist:
                return "Watchlist"
            }
        }
        
        static var allCases: [WatchlistViewModel.Section] {
            [.tickers, .watchlist]
        }
    }
    
    enum Navigation {
        case toTicker(MentionTickerModel)
    }
    
    struct Input {
        let selectedTab: AnyPublisher<Section, Never>
    }
    
    struct Output {
        let sections: AnyPublisher<[DiffableCollectionSection], Never>
        let navigation: AnyPublisher<Navigation, Never>
    }
    
    private let tickerService: TickerServiceInterface
    private let navigation: PassthroughSubject<Navigation, Never> = .init()
    public let nextPage: CurrentValueSubject<Int, Never> = .init(1)
    
    init(tickerService: TickerServiceInterface) {
        self.tickerService = tickerService
    }
    
    func transform(input: Input) -> Output {
        
        let tickers = fetchTickers()
        
        let sections = Publishers.CombineLatest4(input.selectedTab, AppStorage.shared.userPublisher, tickers, nextPage)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .map { (tab, user, allTickers, page) in
                let tickers: [MentionTickerModel]
                switch tab {
                case .tickers:
                    print("(DEBUG) allTicker.count: ", allTickers.count)
                    tickers = allTickers.limit(from: 0, to: page * 100)
                case .watchlist:
                    if let user, let watching = user.watching {
                        let watchListTickers = allTickers.compactMap { ticker -> MentionTickerModel? in
                            guard watching.contains(ticker.ticker) else { return nil }
                            print("(DEBUG) watchlist Ticker: \(ticker.ticker) (in mainThread: \(Thread.isMainThread))", ticker.ticker)
                            return ticker
                        }
                        tickers = watchListTickers
                    } else {
                        tickers = []
                    }
                }
                
                return tickers
            }
            .withUnretained(self)
            .map {
                [$0.tickerSection(tickers: $1)]
            }
            .eraseToAnyPublisher()
        
        return .init(sections: sections, navigation: navigation.eraseToAnyPublisher())
    }
    
    // MARK: - Fetch Tickers
    
    private func fetchTickers() -> AnyPublisher<[MentionTickerModel], Never> {
        tickerService.fetchAllTickers()
            .replaceError(with: [])
            .map { $0.map { coin in .init(ticker: coin.symbol, name: coin.name) } }
            .eraseToAnyPublisher()
    }
    
    
    // MARK: - TickerSection
    
    private func tickerSection(tickers: [MentionTickerModel]) -> DiffableCollectionSection {
        let action: (MentionTickerModel) -> Callback = { ticker in
            { [weak self] in
                self?.navigation.send(.toTicker(ticker))
            }
        }
        
        let cells = tickers.uniqueValues().map { coin in
            return DiffableCollectionItem<TickerCardCellView>(.init(ticker: coin.ticker, name: coin.name, addHorizontal: false, action: action(coin)))
        }
        
        let layout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44), insets: .section(.sectionInsets), spacing: .appVerticalPadding.half)
        
        return .init(Section.tickers.rawValue, cells: cells, sectionLayout: layout)
    }
}
