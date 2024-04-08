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
    
    private let newsService: NewsServiceInterface
    private let preloadedNews: [NewsModel]
    private let selectedTab: CurrentValueSubject<Tab, Never> = .init(Tab.all)
    let nextPage: CurrentValueSubject<Bool, Never>
    private let navigation: PassthroughSubject<Navigation, Never> = .init()
    private var news: [NewsModel] = []
    private var page: Int
    private var limit: Int = 10
    
    public init(newsService: NewsServiceInterface, preloadedNews: [NewsModel] = []){
        self.newsService = newsService
        self.preloadedNews = preloadedNews
        self.nextPage = .init(preloadedNews.isEmpty)
        self.page = preloadedNews.isEmpty ? 0 : 1
    }
    
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
    
    
    // MARK: Section
    
    enum Section: Int {
        case news = 1
    }
    
    
    // MARK: Navigation
    
    enum Navigation {
        case toNews(NewsModel)
    }
    
    func transform() -> Output {
        
        let fetchedNews = nextPage
            .filter({ $0 })
            .map { [weak self] in
                ($0, (self?.page ?? -1) + 1)
            }
            .handleEvents(receiveOutput: { print("(DEBUG) output from nextPage: ", $0) })
            .removeDuplicates(by: { $0.1 == $1.1 })
            .flatMap { [weak self] (nextPage, page) -> AnyPublisher<[NewsModel], Never> in
                guard let self else { return Just([]).setFailureType(to: Never.self).eraseToAnyPublisher() }
                print("(DEBUG) fetching next page: ", page)
                return self.fetchNews(page: page, refresh: true)
            }
        
        let preloadedNews = AnyPublisher<[NewsModel], Never>.just(preloadedNews)
        
        let fetchNews = fetchedNews.merge(with: preloadedNews)
            .map { [weak self] in
                guard let self else { return }
                if !$0.isEmpty {
                    self.page += 1
                }
                if self.news.isEmpty {
                    self.news = $0
                } else {
                    self.news.append(contentsOf: $0)
                }
                return ()
            }
            .eraseToAnyPublisher()
        
        let section = Publishers.CombineLatest(fetchNews, selectedTab)
            .compactMap { [weak self] (_, tab) -> [DiffableCollectionSection]? in
                guard let self else { return nil }
                return self.parseNews(tab: tab)
            }
            .eraseToAnyPublisher()
        
        return .init(section: section, navigation: navigation.eraseToAnyPublisher())
    }
    
    private func fetchNews(page: Int, refresh: Bool) -> AnyPublisher<[NewsModel], Never> {

        newsService.fetchGeneralNews(page: page, limit: 10, refresh: refresh)
            .compactMap(\.data)
            .catch({ err -> AnyPublisher<[NewsModel], Never> in
                print("(ERROR) err while fetching General News: ", err.localizedDescription)
                return .just([])
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: Parse News
    
    private func parseNews(tab: Tab) -> [DiffableCollectionSection] {
        
        let sectionHeaderModel = SegmentControl.Model(selectedTab: selectedTab)
        
        let sectionHeader = CollectionSupplementaryView<SegmentControl<Tab>>(sectionHeaderModel)
        
        let sectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44.0), insets: .sectionInsets, spacing: .appVerticalPadding)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)), pinHeader: true)
        
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
        
        return [DiffableCollectionSection(Section.news.rawValue, cells: cell, header: sectionHeader, sectionLayout: sectionLayout)]
    }
}
