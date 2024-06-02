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
    
    enum WatchlistState {
        case noTickers
        case noUserSession
        case ticker
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
        let watchlistState: AnyPublisher<WatchlistState, Never>
    }
    
    private let tickerService: TickerServiceInterface
    private let navigation: PassthroughSubject<Navigation, Never> = .init()
    private let watchlistState: PassthroughSubject<WatchlistState, Never> = .init()
    public let nextPage: CurrentValueSubject<Int, Never> = .init(1)
    
    init(tickerService: TickerServiceInterface) {
        self.tickerService = tickerService
    }
    
    func transform(input: Input) -> Output {
        
        let tickers = fetchTickers()
        
        let sections: AnyPublisher<[DiffableCollectionSection], Never> = Publishers.CombineLatest4(input.selectedTab, AppStorage.shared.userPublisher, tickers, nextPage)
            .withUnretained(self)
            .map { (vm, combineLatestData) -> ([MentionTickerModel], UserModel?) in
                let (tab, user, allTickers, page) = combineLatestData
                switch tab {
                case .tickers:
                    let tickers = allTickers.limit(from: 0, to: page * 100)
                    return (tickers, user)
                case .watchlist:
                    if let user {
                        if let watching = user.watching {
                            let watchListTickers = allTickers.filter({ watching.contains($0.ticker)})
                            return (watchListTickers, user)
                        } else {
                            return ([], user)
                        }
                    } else {
                        return ([], user)
                    }
                }
            }
            .handleEvents(receiveOutput: { [weak self] (tickers, user) in
                if tickers.isEmpty {
                    if  user != nil {
                        self?.watchlistState.send(.noTickers)
                    } else {
                        self?.watchlistState.send(.noUserSession)
                    }
                } else {
                    self?.watchlistState.send(.ticker)
                }
            })
            .withUnretained(self)
            .map { [$0.tickerSection(tickers: $1.0)] }
            .eraseToAnyPublisher()
        
        return .init(sections: sections,
                     navigation: navigation.eraseToAnyPublisher(),
                     watchlistState: watchlistState.eraseToAnyPublisher())
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
