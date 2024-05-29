//
//  SentimentDetailViewModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 29/05/2024.
//

import DekryptUI
import DekryptService
import Combine
import UIKit
import KKit

fileprivate extension Date {
    var newsDateRange: String {
        let date = dateComponent < 10 ? "0\(dateComponent)" : "\(dateComponent)"
        let month = monthComponent < 10 ? "0\(monthComponent)" : "\(monthComponent)"
        let dateString = "\(month)\(date)\(yearComponent)"
        return "\(dateString)-\(dateString)"
    }
}

class SentimentDetailViewModel {
    
    private let navigation: PassthroughSubject<Navigation, Never> = .init()
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
        let navigation: AnyPublisher<Navigation, Never>
    }
    
    enum Navigation {
        case toNewsDate(SentimentModel, String)
    }
    
    private let sentimentForTicker: SentimentForTicker
    
    init(sentimentForTicker: SentimentForTicker) {
        self.sentimentForTicker = sentimentForTicker
    }
    
    func transform() -> Output {
        let section = Just(())
            .withUnretained(self)
            .map { vm, _ in [vm.setupSummarySection(), vm.setupCalendarSection()].compactMap({ $0 }) }
            .setFailureType(to: Never.self)
            .eraseToAnyPublisher()
        
        return .init(section: section, navigation: navigation.eraseToAnyPublisher())
    }
    
    
    private func setupSummarySection() -> DiffableCollectionSection {
        let sentimentSummaryCell = DiffableCollectionItem<SentimentDetailSummaryView>(sentimentForTicker)
        
        let sectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .absolute(450), insets: .sectionInsets)
            .addHeader()
        
        let header = CollectionSupplementaryView<SectionHeader>(.init(label: "Summary", addHorizontalInset: false))
        
        return .init(0, cells: [sentimentSummaryCell], header: header, sectionLayout: sectionLayout)
    }
    
    
    private func setupCalendarSection() -> DiffableCollectionSection? {
        
        guard let timeline = sentimentForTicker.timeline else { return nil }
        
        let sortedTimeline = timeline.sorted(by: { $0.key.date! < $1.key.date! }).dropFirst(timeline.count - 30)
        
        let initialSkips: Int =  {
            guard let firstWeekend = sortedTimeline.first?.key.date?.component(.weekday) as? Int else { return 0 }
            return firstWeekend - 1
        }()
        
        let initialSkipCells = (0..<initialSkips).map { DiffableCollectionItem<SentimentDateDayView>(.empty($0)) }
        
        let dates = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map { DiffableCollectionItem<SentimentDateDayView>(.day($0)) }
        
        
        let timelineDateCellAction: (SentimentModel, Date) -> Callback = { [weak self] (model, date) in
            { self?.navigation.send(.toNewsDate(model, date.newsDateRange)) }
        }
        let cells = timeline.sorted(by: { $0.key.date! < $1.key.date! }).dropFirst(timeline.count - 30).compactMap { (timestamp, sentiment) -> DiffableCollectionCellProvider? in
            guard let date = timestamp.date else { return nil }
            return DiffableCollectionItem<SentimentCalendarDateView>(.init(date: date, sentiment: sentiment.sentimentType, sentimentScore: sentiment.sentimentScore ?? 0, action: timelineDateCellAction(sentiment, date)))
        }
        
        let header = CollectionSupplementaryView<SectionHeader>(.init(label: "Calendar", addHorizontalInset: false))
        
        let itemDim = (CGFloat.totalWidth - 2 * CGFloat.appHorizontalPadding - 6 * .appHorizontalPadding.half)/7
        
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .absolute(itemDim), heightDimension: .absolute(itemDim)))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100)), subitems: [item])
        group.interItemSpacing = .fixed(.appHorizontalPadding.half)
        
        let sectionLayout = NSCollectionLayoutSection(group: group)
        sectionLayout.interGroupSpacing = .appVerticalPadding.half
        sectionLayout.contentInsets = .sectionInsets
        sectionLayout.addHeader()
        
        return .init(1, cells: dates + initialSkipCells + cells, header: header, sectionLayout: sectionLayout)
        
        
    }
}
