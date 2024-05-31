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
        case general, futures, institutions, taxes, upgrade, whales, mining, NFT, podcast, pricemovement, priceforecast, regulations, stablecoins, tanalysis
       
        var value: String {
            if case .NFT = self {
                return "NFT"
            } else if case .priceforecast = self {
                return "Price Forecast"
            } else if case .pricemovement = self {
                return "Price Movement"
            } else {
                return rawValue.capitalized
            }
            
        }
        
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
    private let selectedTab: CurrentValueSubject<Tab, Never> = .init(Tab.general)
    let nextPage: CurrentValueSubject<Bool, Never>
    private let refreshData: CurrentValueSubject<Bool, Never> = .init(false)
    private var isRefreshing: Bool { refreshData.value }
    private let navigation: PassthroughSubject<Navigation, Never> = .init()
    
    private let type: FeedType
    private var news: [Tab : [NewsModel]] = [:]
    private var page: [Tab : Int] = [:]
    private var limit: Int = 10
    private let includeSegmentControl: Bool
    
    init(newsService: NewsServiceInterface, includeSegmentControl: Bool = true, type: FeedType = .feed) {
        self.newsService = newsService
        self.includeSegmentControl = includeSegmentControl
        self.preloadedNews = type.preloadedNews
        self.nextPage = .init(type.preloadedNews.isEmpty)
        self.page = [.general : type.page]
        self.type = type
    }
    
    func transform() -> Output {
        
        let refreshedNews = refreshData
            .filter({ $0 })
            .handleEvents(receiveOutput: { [weak self] (_) in
                guard let self else { return }
                let tab = self.selectedTab.value
                self.page[tab] = 1
                self.news[tab]?.removeAll()
            })
            .withUnretained(self)
            .flatMap { (vm, refresh) in
                let tab = vm.selectedTab.value
                return vm.fetchNews(selectedTab: tab, refresh: refresh)
            }
            .eraseToAnyPublisher()
        
        let fetchNextPageNews = nextPage
            .filter({ [weak self] nextPage in
                guard let self else { return false }
                return nextPage && !self.isRefreshing
            })
            .flatMap { [weak self] (_) -> AnyPublisher<[NewsModel], Never> in
                guard let self else { return .just([]) }
                let selectedTab = self.selectedTab.value
                return self.fetchNextPageForCurrentTab(selectedTab: selectedTab)
            }
            .eraseToAnyPublisher()
        
        let preloadedNews = AnyPublisher<[NewsModel], Never>.just(preloadedNews).handleEvents(receiveOutput: { [weak self] preloadedNews in
            guard let self else { return }
            self.news[.general] = preloadedNews
        }).eraseToAnyPublisher()
        
        let fetchNews = Publishers.Merge3(fetchNextPageNews, refreshedNews, preloadedNews)
            .eraseToAnyPublisher()
        
        // MARK: FetchNewsBasedOnTab
    
        let fetchNewsBasedOnTab = selectedTab
            .dropFirst(1)
            .withUnretained(self)
            .flatMap { (vm, tab) -> AnyPublisher<[NewsModel], Never> in
                if tab != .general {
                    if let news = vm.news[tab] {
                        return .just(news)
                    }
                    return vm.fetchNewsForTopic(topic: tab.rawValue.lowercased(), page: vm.page[tab] ?? 1, refresh: false)
                } else {
                    if let generalNews = vm.news[.general] {
                        return .just(generalNews)
                    }
                    return vm.fetchGeneralNews(page: vm.page[tab] ?? 1, refresh: false)
                }
            }
            .eraseToAnyPublisher()

        // MARK: Section
        
        let section = Publishers.Merge(fetchNews, fetchNewsBasedOnTab)
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self else { return }
                if self.refreshData.value {
                    self.refreshData.send(false)
                }
            })
            .compactMap { [weak self] (news) -> [DiffableCollectionSection]? in
                guard let self else { return nil }
                let tab = self.selectedTab.value
                return self.setupNewsSection(news: self.news[tab] ?? news, tab: tab)
            }
            .eraseToAnyPublisher()
        
        return .init(section: section, navigation: navigation.eraseToAnyPublisher())
    }
    
    private func fetchNextPageForCurrentTab(selectedTab tab: Tab) -> AnyPublisher<[NewsModel], Never> {
        let page = (page[tab] ?? 0) + 1
    
        return Just((page, tab))
            .removeDuplicates(by: { $0.0 == $1.0 })
            .withUnretained(self)
            .flatMap { (vm, combinedData) in
                vm.fetchNews(selectedTab: combinedData.1, page: combinedData.0, refresh: false)
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchNews(selectedTab tab: Tab, page pageToLoad: Int? = nil, refresh: Bool) -> AnyPublisher<[NewsModel], Never> {
        
        let newsPublisher: AnyPublisher<[NewsModel], Never>
        let page = pageToLoad ?? (page[tab] ?? 1)
        let tabName = tab.rawValue.lowercased()
        
        if (tab == .general) {
            newsPublisher = fetchGeneralNews(page: page, refresh: refresh)
        } else {
            newsPublisher = fetchNewsForTopic(topic: tabName, page: page, refresh: refresh)
        }
        
        return newsPublisher
            .handleEvents(receiveOutput: { [weak self] fetchedNews in
                guard let vm = self else { return }
                vm.updatingPageAndNewsModels(tab: tab, fetchedNews: fetchedNews)
            })
            .eraseToAnyPublisher()
    }
    
    private func fetchGeneralNews(page: Int, refresh: Bool) -> AnyPublisher<[NewsModel], Never> {
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
    
    private func fetchNewsForTopic(topic: String, page: Int , refresh: Bool) -> AnyPublisher<[NewsModel], Never> {
        newsService.newsSearch(query: "", page: page, limit: 10, refresh: refresh, topic: topic)
            .compactMap(\.data)
            .catch({ err -> AnyPublisher<[NewsModel], Never> in
                print("(ERROR) err while fetching Topic (\(topic)) News: ", err.localizedDescription)
                return .just([])
            })
            .eraseToAnyPublisher()
    }
    
    private func updatingPageAndNewsModels(tab: Tab, fetchedNews: [NewsModel]) {
        let page = self.page[tab] ?? 1
        if !fetchedNews.isEmpty {
            self.page[tab] = page + 1
        }
        
        let newsForTab = self.news[tab] ?? []
        
        if newsForTab.isEmpty {
            self.news[tab] = fetchedNews
        } else {
            let removedDuplicates = fetchedNews.filter { news in
                !newsForTab.contains { newsEl in
                    newsEl == news
                }
            }
            self.news[tab]?.append(contentsOf: removedDuplicates)
        }
    }
    
    
    // MARK: Parse News
    
    private func setupNewsSection(news: [NewsModel], tab: Tab) -> [DiffableCollectionSection] {
        
        let sectionHeaderModel = SegmentControl.Model(selectedTab: selectedTab)
        
        let sectionHeader = CollectionSupplementaryView<SegmentControl<Tab>>(sectionHeaderModel)
        
        let sectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44.0), insets: .sectionInsets, spacing: .appVerticalPadding)
          
        if includeSegmentControl {
            sectionLayout.addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)), pinHeader: true)
        }
        
        let cell = news.indices
            .compactMap { idx -> (DiffableCollectionCellProvider)? in
                let newsArticle = news[idx]
                let action: Callback = { [weak self] in
                    self?.navigation.send(.toNews(newsArticle))
                }
                let cell = DiffableCollectionItem<NewsView>(.init(model: newsArticle, 
                                                                  isFirst: idx == 0,
                                                                  isLast: idx == news.count - 1,
                                                                  action: action))
                return cell
            }
        
        return [DiffableCollectionSection(Section.news.rawValue, cells: cell, header: includeSegmentControl ? sectionHeader : nil, sectionLayout: sectionLayout)]
    }
    
    
    // MARK: - Refresh
    
    public func refresh() {
        refreshData.send(true)
    }
}
