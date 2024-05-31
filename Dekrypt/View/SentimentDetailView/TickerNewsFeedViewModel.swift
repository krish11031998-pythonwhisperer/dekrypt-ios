//
//  TickerNewsFeedViewModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 28/05/2024.
//

import Combine
import DekryptService
import DekryptUI
import UIKit
import KKit

class TickerNewsFeedViewModel {
    
    private let newsService: NewsServiceInterface
    private let ticker: String
    private let date: String
    private let refresh: CurrentValueSubject<Void, Never> = .init(())
    private let navigation: PassthroughSubject<Navigation, Never> = .init()
    
    init(newsService: NewsServiceInterface, ticker: String, date: String) {
        self.newsService = newsService
        self.ticker = ticker
        self.date = date
    }
    
    enum Navigation {
        case toNews(NewsModel)
    }
    
    struct Output {
        let sections: AnyPublisher<[DiffableCollectionSection], Never>
        let navigation: AnyPublisher<Navigation, Never>
    }
    
    func transform() -> Output {
        let refreshSection = refresh
            .withUnretained(self)
            .flatMap { (vm, _) in
                vm.fetchNews(ticker: vm.ticker, date: vm.date, page: 0, limit: 100, refresh: false)
                    .compactMap { [weak vm] news in
                        vm?.setupNewsSection(fetchedNews: news)
                    }
                    .eraseToAnyPublisher()
            }
            .map { [$0] }
            .eraseToAnyPublisher()
        
        return .init(sections: refreshSection, navigation: navigation.eraseToAnyPublisher())
        
    }
    
    
    // MARK: - Fetch News Section
    
    private func fetchNews(ticker: String, date: String, page: Int, limit: Int, refresh: Bool) -> AnyPublisher<[NewsModel], Never> {
        newsService.fetchNewsForAllTickers(entity: nil, ticker: ticker, source: nil, date: date, page: page, limit: limit, refresh: refresh)
            .replaceError(with: .init(data: nil, success: false, err: nil))
            .compactMap(\.data)
            .eraseToAnyPublisher()
    }
    
    
    // MARK: - Build Collection Section
    
    private func setupNewsSection(fetchedNews: [NewsModel]) -> DiffableCollectionSection {
        
        let action: (NewsModel) -> Callback = { [weak self] news in
            {
                self?.navigation.send(.toNews(news))
            }
        }
        
        let cells = fetchedNews.indices.map { idx in
            let news = fetchedNews[idx]
            return DiffableCollectionItem<NewsView>(.init(model: news, isFirst: idx == 0, isLast: idx == fetchedNews.count - 1, action: action(news)))
        }
        
        let layout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44.0), insets: .sectionInsets, spacing: .appVerticalPadding)
        
        return .init(0, cells: cells, sectionLayout: layout)
    }
    
}
