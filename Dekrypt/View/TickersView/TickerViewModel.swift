//
//  TickerViewModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 13/02/2024.
//

import Foundation
import KKit
import DekryptUI
import Combine
import DekryptService
import UIKit

extension MentionTickerModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sentimentScore)
        hasher.combine(positiveMentions)
        hasher.combine(neutralMentions)
        hasher.combine(negativeMentions)
        hasher.combine(totalMentions)
    }
}

class TickerViewModel {
    
    private let tickers: [MentionTickerModel]
    private let selectedTab: CurrentValueSubject<Tab, Never> = .init(.topMention)
    private let selectedNavigation: PassthroughSubject<Navigation, Never> = .init()
    
    init(tickers: [MentionTickerModel]) {
        self.tickers = tickers
    }
    
    enum Section: Int {
        case tickers = 0
    }
    
    enum Navigation {
        case toTicker(String, String)
    }
    
    enum Tab: SegmentType {
        case topMention, positiveMention, negativeMention
        
        var value: String {
            switch self {
            case .topMention:
                return "Top Mentions"
            case .positiveMention:
                return "Positive Mentions"
            case .negativeMention:
                return "Negative Mentions"
            }
        }
        
        static var allTabs: [TickerViewModel.Tab] {
            [.topMention, .positiveMention, .negativeMention]
        }
        
    }
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
        let selectedNavigation: AnyPublisher<Navigation, Never>
    }
    
    func transform() -> Output {
        
        let sectionPublisher: AnyPublisher<[DiffableCollectionSection], Never> = selectedTab
            .withUnretained(self)
            .map { (vm, tab) in
                let header = CollectionSupplementaryView<SegmentControl<Tab>>(.init(selectedTab: vm.selectedTab))
                
                let sectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44.0), insets: .section(.init(vertical: .standardColumnSectionSpacing, horizontal: 0)), spacing: .standardColumnSpacing)
                    .addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
                                pinHeader: true)
                
                let cells = vm.tickers.filter { ticker in
                    switch tab {
                    case .negativeMention:
                        return ticker.sentimentScore < 0
                    case .positiveMention:
                        return ticker.sentimentScore > 0
                    default:
                        return true
                    }
                }
                .sorted {
                    switch tab {
                    case .topMention:
                        return $0.totalMentions > $1.totalMentions
                    case .positiveMention:
                        return $0.sentimentScore > $1.sentimentScore
                    case .negativeMention:
                        return $0.sentimentScore < $1.sentimentScore
                    }
                }
                .map({ ticker in
                    let action = {
                        vm.selectedNavigation.send(.toTicker(ticker.ticker, ticker.name))
                    }
                    return DiffableCollectionItem<TickerCardCellView>(.init(mention: ticker, action: action))
                })
                
                let section: DiffableCollectionSection = .init(Section.tickers.rawValue, cells: cells, header: header, sectionLayout: sectionLayout)
                
                return section
            }
            .map({ [$0] })
            .eraseToAnyPublisher()
            
            
        
        return .init(section: sectionPublisher, selectedNavigation: selectedNavigation.eraseToAnyPublisher())
        
    }
    
}
