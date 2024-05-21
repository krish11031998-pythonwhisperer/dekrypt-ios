//
//  EventDetailViewModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 13/02/2024.
//

import Foundation
import UIKit
import Combine
import KKit
import DekryptUI
import DekryptService

class EventDetailViewModel {
    
    enum Section: Int {
        case heading = 0, tickers, sentiments, news
        
        var name: String {
            switch self {
            case .heading:
                return "Heading"
            case .tickers:
                return "Tickers"
            case .sentiments:
                return "Sentiments"
            case .news:
                return "News"
            }
        }
    }
    
    enum Navigation {
        case selectedNews(news: NewsModel)
        case viewMoreNews(news: [NewsModel])
        case toTickerDetail(ticker: String)
    }
    
    private let eventModel: EventModel
    private let newsService: NewsServiceInterface
    private let selectedNews: PassthroughSubject<NewsModel?, Never>
    private var bag: Set<AnyCancellable> = .init()
    private let viewMoreArticles: PassthroughSubject<Void, Never> = .init()
    private let selectedTicker: PassthroughSubject<String, Never> = .init()
    private let errorMessage: PassthroughSubject<String, Never> = .init()
    
    var needToLoadNews: Bool { eventModel.news?.isEmpty ?? true }
    
    init(eventModel: EventModel, newsService: NewsServiceInterface = NewsService.shared) {
        self.newsService = newsService
        self.eventModel = eventModel
        self.selectedNews = .init()
    }
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
        let navigation: AnyPublisher<Navigation, Never>
        let eventName: StringPublisher<Never>
    }
    
    //MARK: - Exposed Methods
    func transform() -> Output {
        
        // Event Section 
        
        let eventSection: AnyPublisher<[DiffableCollectionSection], Never> = Just(eventModel)
            .withUnretained(self)
            .compactMap { (vm, eventModel) in
                let headerView = vm.headerView()
                let tickers = vm.tickersInEvent(tickers: vm.eventModel.tickers ?? [])
                return [headerView, tickers].compactMap({ $0 })
            }
            .eraseToAnyPublisher()
        
        // News Section
        
        let preLoadNewsArticles: AnyPublisher<[NewsModel], Never> = Just(eventModel.news)
            .setFailureType(to: Never.self)
            .compactMap({ $0 })
            .eraseToAnyPublisher()
        
        let newsForEvent: AnyPublisher<[NewsModel], Never> = Just(eventModel.news)
            .filter({ $0 == nil })
            .withUnretained(self)
            .flatMap { (vm, _) in
                vm.newsService.fetchNewsForEvent(eventId: vm.eventModel.eventId, refresh: false)
            }
            .catch { [weak self] error -> AnyPublisher<NewsResult, Never> in
                self?.errorMessage.send(error.localizedDescription)
                return .just(.init(data: nil, success: false, err: nil))
            }
            .compactMap(\.data)
            .eraseToAnyPublisher()
        
        let newsAritcles = Publishers.Merge(preLoadNewsArticles, newsForEvent).eraseToAnyPublisher()
        
        let newsAndSentimentSection: AnyPublisher<[DiffableCollectionSection], Never> = newsAritcles
            .withUnretained(self)
            .compactMap { (vm, news) in
                [vm.sentimentNewsSentiment(news: news), vm.newsSection(news: news)]
            }
            .eraseToAnyPublisher()
        
        // All Sections
        
        let section: AnyPublisher<[DiffableCollectionSection], Never> = Publishers.CombineLatest(eventSection, newsAndSentimentSection)
            .map { $0 + $1 }
            .eraseToAnyPublisher()
        
        // Navigation
        
        let moreArticles = viewMoreArticles.withLatestFrom(newsAritcles)
            .map { Navigation.viewMoreNews(news: $0.1) }
            .eraseToAnyPublisher()
        
        let articleDetail = selectedNews
            .removeDuplicates { $0?.newsId != $1?.newsId }
            .compactMap { $0 }
            .map { Navigation.selectedNews(news: $0) }
            .eraseToAnyPublisher()
        
        let viewTicker = selectedTicker
            .map { Navigation.toTickerDetail(ticker: $0) }
            .eraseToAnyPublisher()
        
        let navigation = Publishers.MergeMany(moreArticles, articleDetail, viewTicker).eraseToAnyPublisher()
        
        let eventName = Just(eventModel.eventName)
            .setFailureType(to: Never.self)
            .eraseToAnyPublisher()
        
        return .init(section: section, navigation: navigation, eventName: eventName)
    }
    
    
    //MARK: - Protected Methods
    
    private func headerView() -> DiffableCollectionSection {
        let sectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(100), insets: .section(.init(vertical: .standardColumnSpacing, horizontal: 0)))
        return .init(Section.heading.rawValue, cells: [DiffableCollectionCellView<EventDetailViewHeader>(model: .init(event: eventModel))], sectionLayout: sectionLayout)
    }
    
    private func tickersInEvent(tickers: [String]?) -> DiffableCollectionSection? {
        guard let tickers, !tickers.isEmpty else { return nil }
        let action: ((String) -> Void) = { [weak self] ticker in
            self?.selectedTicker.send(ticker)
        }
        let cell = DiffableCollectionItem<TickerGrid>(.init(tickers: tickers, action: action))
        
        let height = TickerGrid.height(tickers: tickers, width: .totalWidth - (2 * .appHorizontalPadding)) + (2 * .standardColumnSpacing)
        
        let sectionLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1), height: .absolute(height), insets: .section(.init(top: .standardColumnSpacing, leading: 0, bottom: .zero, trailing: 0)), spacing: .standardColumnSpacing)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44)))
        
        let header = CollectionSectionHeader(.init(label: Section.tickers.name, addHorizontalInset: true))
        
        let section = DiffableCollectionSection(Section.tickers.rawValue, cells: [cell], header: header, sectionLayout: sectionLayout)
        
        
        return section
    }
    
    private func sentimentNewsSentiment(news: [NewsModel]) -> DiffableCollectionSection {
        var positive: Int = 0
        var negative: Int = 0
        var neutral: Int = 0
        
        for singleNews in news {
            switch singleNews.sentiment {
            case .positve:
                positive += 1
            case .negative:
                negative += 1
            case .neutral:
                neutral += 1
            }
        }
        let model = SentimentModel.init(neutral: neutral, positive: positive, negative: negative, sentimentScore: nil)
        
        let sectionLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1.0),
                                                                           height: .absolute(300),
                                                                           insets: .section(.init(top: .standardColumnSpacing, leading: 0, bottom: .standardColumnSectionSpacing, trailing: 0)))
            .addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44.0)))
        
        let header = CollectionSectionHeader(.init(label: Section.sentiments.name))
        
        let section: DiffableCollectionSection = .init(Section.sentiments.rawValue, cells: [DiffableCollectionItem<SentimentSegmentChart>(model)], header: header, sectionLayout: sectionLayout)
        
        return section
    }
    
    private func newsSection(news: [NewsModel]) -> DiffableCollectionSection {
     
        let limitedNews = news
        let newsCells = limitedNews.indices.map { idx in
            let news = limitedNews[idx]
            let cellModel = NewsViewModel(model: news, isFirst: idx == 0, isLast: idx == (limitedNews.count - 1)) { [weak self] in
                self?.selectedNews.send(news)
            }
            
            return DiffableCollectionItem<NewsView>(cellModel)
        }
        
        let sectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44.0), insets: .sectionInsets, spacing: .appVerticalPadding)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44.0)))
        
        let header = CollectionSupplementaryView<SectionHeader>(.init(label: Section.news.name, addHorizontalInset: false))
        
        return .init(Section.news.rawValue, cells: newsCells, header: header, sectionLayout: sectionLayout)
    }
}

