//
//  NewsViewModel .swift
//  DekryptUI_Example
//
//  Created by Krishna Venkatramani on 14/01/2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import KKit
import Combine
import DekryptUI
import DekryptService
import UIKit

fileprivate struct HighlightModel: Codable {
    let news: [NewsModel]
}

fileprivate typealias HighlightResponse = GenericResult<HighlightModel>
fileprivate typealias NewsResponse = GenericResult<[NewsModel]>

public class NewsFeedViewControllerModel {
    
    // MARK: Tab
    
    enum Tab: String, CaseIterable, SegmentType {
        case all, positive, negative, neutral, libra, top
        
        var value: String { rawValue.capitalized }
        
        static var allTabs: [NewsFeedViewControllerModel.Tab] { Self.allCases }
    }
    
    
    // MARK: Output
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
        let navigation: AnyPublisher<Navigation, Never>
    }
    
    
    // MARK: PreloadFeedModel
    
    struct PreloadedFeedModel {
        let news: [NewsModel]
        let query: String?
        let page: Int
        
        init(news: [NewsModel], query: String? = nil, page: Int = 1) {
            self.news = news
            self.query = query
            self.page = page
        }
    }
    
    // MARK: FeedType
    
    enum FeedType {
        case feed
        case preloaded(PreloadedFeedModel)
        
        var preloadedNews: [NewsModel] {
            switch self {
            case .feed:
                return []
            case .preloaded(let preloadedFeedModel):
                return preloadedFeedModel.news
            }
        }
        
        var page: Int {
            switch self {
            case .feed:
                return 0
            case .preloaded(let preloadedFeedModel):
                return preloadedFeedModel.page
            }
        }
    }
    
    // MARK: Section
    
    enum Section: Int {
        case news = 1
    }
    
    
    // MARK: Navigation
    
    enum Navigation {
        case toNews(NewsModel)
    }
    
    private let newsService: NewsServiceInterface
    private let preloadedNews: [NewsModel]
    private let selectedTab: CurrentValueSubject<Tab, Never> = .init(Tab.all)
    let nextPage: CurrentValueSubject<Bool, Never>
    private let refreshData: CurrentValueSubject<Bool, Never> = .init(false)
    private let navigation: PassthroughSubject<Navigation, Never> = .init()
    
    private let type: FeedType
    private var news: [NewsModel] = []
    private var page: Int
    private var limit: Int = 10
    private let includeSegmentControl: Bool
    
    init(newsService: NewsServiceInterface, includeSegmentControl: Bool = true, type: FeedType = .feed) {
        self.newsService = newsService
        self.includeSegmentControl = includeSegmentControl
        self.preloadedNews = type.preloadedNews
        self.nextPage = .init(type.preloadedNews.isEmpty)
        self.page = type.page
        self.type = type
    }
    
    func transform() -> Output {
        
        let refreshedNews = refreshData
            .filter({ $0 })
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.page = 0
                self?.news.removeAll()
            })
            .withUnretained(self)
            .flatMap { (vm, refresh) in
                vm.fetchNews(page: 0, refresh: refresh)
            }
            .eraseToAnyPublisher()
        
        let fetchedNews = nextPage
            .filter({ [weak self] in
                guard let self else { return false }
                return $0 && !self.refreshData.value
            })
            .map { [weak self] in ($0, (self?.page ?? -1) + 1) }
            .removeDuplicates(by: { $0.1 == $1.1 })
            .flatMap { [weak self] (nextPage, page) -> AnyPublisher<[NewsModel], Never> in
                guard let self else { return Just([]).setFailureType(to: Never.self).eraseToAnyPublisher() }
                print("(DEBUG) fetching next page: ", page)
                return self.fetchNews(page: page, refresh: true)
            }
        
        let preloadedNews = AnyPublisher<[NewsModel], Never>.just(preloadedNews)
        
        let fetchNews = Publishers.Merge3(fetchedNews, refreshedNews, preloadedNews)
            .withUnretained(self)
            .map { (vm, fetchedNews) in
                if !fetchedNews.isEmpty {
                    vm.page += 1
                }
                if vm.news.isEmpty {
                    vm.news = fetchedNews
                } else {
                    let removedDuplicates = fetchedNews.filter { news in
                        !vm.news.contains { newsEl in
                            newsEl == news
                        }
                    }
                    vm.news.append(contentsOf: removedDuplicates)
                }
                return ()
            }
            .eraseToAnyPublisher()
        
        let section = Publishers.CombineLatest(fetchNews, selectedTab)
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self else { return }
                if self.refreshData.value {
                    self.refreshData.send(false)
                }
            })
            .compactMap { [weak self] (_, tab) -> [DiffableCollectionSection]? in
                guard let self else { return nil }
                return self.setupNewsSection(tab: tab)
            }
            .eraseToAnyPublisher()
        
        return .init(section: section, navigation: navigation.eraseToAnyPublisher())
    }
    
    private func fetchNews(page: Int, refresh: Bool) -> AnyPublisher<[NewsModel], Never> {
        let newsResult: AnyPublisher<NewsResult, Error>
        if case .preloaded(let preloadedFeedModel) = type, let query = preloadedFeedModel.query {
            newsResult = newsService.newsSearch(query: query, page: page, limit: 10, refresh: refresh, topic: nil)
        } else {
            newsResult = newsService.fetchGeneralNews(page: page, limit: 10, refresh: refresh)
        }
        return newsResult
            .compactMap(\.data)
            .catch({ err -> AnyPublisher<[NewsModel], Never> in
                print("(ERROR) err while fetching General News: ", err.localizedDescription)
                return .just([])
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: Parse News
    
    private func setupNewsSection(tab: Tab) -> [DiffableCollectionSection] {
        
        let sectionHeaderModel = SegmentControl.Model(selectedTab: selectedTab)
        
        let sectionHeader = CollectionSupplementaryView<SegmentControl<Tab>>(sectionHeaderModel)
        
        let sectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44.0), insets: .sectionInsets, spacing: .appVerticalPadding)
          
        if includeSegmentControl {
            sectionLayout.addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)), pinHeader: true)
        }
        
        let cell = self.news.indices
            .compactMap { idx -> (DiffableCollectionCellProvider)? in
                let newsArticle = news[idx]
                let action: Callback = { [weak self] in
                    self?.navigation.send(.toNews(newsArticle))
                }
                let cell = DiffableCollectionItem<NewsView>(.init(model: newsArticle, 
                                                                  isFirst: idx == 0,
                                                                  isLast: idx == news.count - 1,
                                                                  action: action))
                switch tab {
                case .all:
                    return cell
                case .positive:
                    if newsArticle.sentiment == .positve {
                        return cell
                    }
                case .neutral:
                    if newsArticle.sentiment == .neutral {
                        return cell
                    }
                case .negative:
                    if newsArticle.sentiment == .negative {
                        return cell
                    }
                case .libra:
                    if newsArticle.topics?.contains(where: { $0 == "libra"}) == true {
                        return cell
                    }
                default:
                    return nil
                }
                
                return nil
            }
        
        return [DiffableCollectionSection(Section.news.rawValue, cells: cell, header: includeSegmentControl ? sectionHeader : nil, sectionLayout: sectionLayout)]
    }
    
    
    // MARK: - Refresh
    
    public func refresh() {
        refreshData.send(true)
    }
}
