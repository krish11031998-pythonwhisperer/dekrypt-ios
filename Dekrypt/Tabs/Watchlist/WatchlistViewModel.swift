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
    
    
    enum Section: Int {
        case tickers = 0
    }

    enum Navigation {
        case toTicker(MentionTickerModel)
    }
    struct Output {
        let sections: AnyPublisher<[DiffableCollectionSection], Never>
        let navigation: AnyPublisher<Navigation, Never>
    }
    
    private let tickerService: TickerServiceInterface
    private let navigation: PassthroughSubject<Navigation, Never> = .init()
    
    init(tickerService: TickerServiceInterface) {
        self.tickerService = tickerService
    }
    
    func transform() -> Output {
        
        let tickers = fetchTickers()
        
        return .init(sections: tickers, navigation: navigation.eraseToAnyPublisher())
    }
    
    
    private func fetchTickers() -> AnyPublisher<[DiffableCollectionSection], Never> {
        tickerService.fetchAllTickers()
            .replaceError(with: [])
            .map { coins in
                
                let action: (MentionTickerModel) -> Callback = { ticker in
                    { [weak self] in
                        self?.navigation.send(.toTicker(ticker))
                    }
                }
                
                let cells = coins.uniqueValues().map { coin in
                    let model = MentionTickerModel(ticker: coin.symbol, name: coin.name)
                    return DiffableCollectionItem<TickerCardCellView>(.init(mention: model, addHorizontal: false, action: action(model)))
                }
                
                let layout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44), insets: .section(.sectionInsets), spacing: .appVerticalPadding.half)
                
                return [DiffableCollectionSection(Section.tickers.rawValue, cells: cells, sectionLayout: layout)]
            }
            .eraseToAnyPublisher()
    }
}
