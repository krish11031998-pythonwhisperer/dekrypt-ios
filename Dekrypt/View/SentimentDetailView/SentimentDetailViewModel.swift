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
        return .init(navigation: navigation.eraseToAnyPublisher())
    }
    
    func section() -> [DiffableCollectionSection] {
        [self.setupSummarySection(), self.setupCalendarSection()].compactMap({ $0 })
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
  
        var sortedTimeline: [(Date,SentimentModel)] = []
        
        for day in (0..<30).reversed() {
            guard let date = Calendar.current.date(byAdding: .day, value: -day, to: .now) else { continue }
            let monthComponent = date.monthComponent < 10 ? "0\(date.monthComponent)" : "\(date.monthComponent)"
            let dateComponent = date.dateComponent < 10 ? "0\(date.dateComponent)" : "\(date.dateComponent)"
            guard let sentiment = timeline["\(date.yearComponent)-\(monthComponent)-\(dateComponent)"] else { continue }
            sortedTimeline.append((date, sentiment))
        }
        
        let initialSkips: Int =  {
            guard let firstWeekDay = sortedTimeline.first?.0.component(.weekday) as? Int else { return 0 }
            return firstWeekDay - 1
        }()
        
        let initialSkipCells = (0..<initialSkips).map { DiffableCollectionItem<SentimentDateDayView>(.empty($0)) }
        
        let dates = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map { DiffableCollectionItem<SentimentDateDayView>(.day($0)) }
        
        
        let timelineDateCellAction: (SentimentModel, Date) -> Callback = { [weak self] (model, date) in
            { self?.navigation.send(.toNewsDate(model, date.newsDateRange)) }
        }
        
        let cells = sortedTimeline.compactMap { (date, sentiment) -> DiffableCollectionCellProvider? in
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
