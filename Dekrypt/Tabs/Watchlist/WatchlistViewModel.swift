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
    
    enum WatchlistResult {
        case noTickers(DiffableCollectionSection)
        case noUserSession(DiffableCollectionSection)
        case ticker(DiffableCollectionSection)
    }
    
    enum Navigation {
        case toTicker(MentionTickerModel)
    }
    
    struct Input {
        let selectedTab: AnyPublisher<Section, Never>
    }
    
    struct Output {
        let sections: AnyPublisher<WatchlistResult, Never>
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
        
        let sections: AnyPublisher<WatchlistResult, Never> = Publishers.CombineLatest4(input.selectedTab, AppStorage.shared.userPublisher, tickers, nextPage)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .withUnretained(self)
            .map { (vm, combineLatestData) in
                let (tab, user, allTickers, page) = combineLatestData
                let result: WatchlistResult
                switch tab {
                case .tickers:
                    print("(DEBUG) allTicker.count: ", allTickers.count)
                    let tickers = allTickers.limit(from: 0, to: page * 100)
                    result = .ticker(vm.tickerSection(tickers: tickers))
                case .watchlist:
                    if let user {
                        if let watching = user.watching {
                            let watchListTickers = allTickers.filter({ watching.contains($0.ticker)})
                            result = .ticker(vm.tickerSection(tickers: watchListTickers))
                        } else {
                            result = .noTickers(vm.tickerSection(tickers: []))
                        }
                    } else {
                        result = .noUserSession(vm.tickerSection(tickers: []))
                    }
                }
                
                return result
            }
            .eraseToAnyPublisher()
        
        return .init(sections: sections,
                     navigation: navigation.eraseToAnyPublisher())
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
