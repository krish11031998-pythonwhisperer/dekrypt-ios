//
//  SearchViewModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 08/04/2024.
//

import UIKit
import KKit
import DekryptUI
import DekryptService
import Combine

class SearchViewModel {
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
    }
    
    enum Section: Int, Hashable {
        case coinOfTheDay = 1
        case trendingCoins
        case tickers
        case news
        case recentlySearch
        
        var name: String {
            switch self {
            case .coinOfTheDay:
                return "Coin of the day"
            case .trendingCoins:
                return "Trending Coins"
            case .tickers:
                return "Tickers"
            case .news:
                return "News"
            case .recentlySearch:
                return "Recently Searched"
            }
        }
    }
    
    enum Navigation {
        case toNews(NewsModel)
        case toNewsFeed([NewsModel], String)
        case toTicker(ticker: String, name: String)
    }
    
    private(set) var searchParam: PassthroughSubject<String?, Never> = .init()
    private(set) var navigation: PassthroughSubject<Navigation, Never> = .init()
    private let newsSearchService: NewsServiceInterface
    private let tickerSearchService: TickerServiceInterface
    private let lunarService: LunarCrushServiceInterface
    private let errorMessage: PassthroughSubject<String?, Error> = .init()
    
    init(tickerSearchService: TickerServiceInterface, newsSearchService: NewsServiceInterface, lunarService: LunarCrushServiceInterface) {
        self.tickerSearchService = tickerSearchService
        self.newsSearchService = newsSearchService
        self.lunarService = lunarService
    }
    
    func transform() -> Output {
        let placeHolderSection = tickerSearchService.fetchAllTickers()
            .catchWithErrorWithNever(errHandle: errorMessage, withErr: URLSessionError.invalidResponse)
            .withUnretained(self)
            .map { (vm, coinList) in
                return [vm.setupCoinsOfTheDay(coinList)]
            }
            .eraseToAnyPublisher()
        
        let search: AnyPublisher<[DiffableCollectionSection], Never> = searchParam
            //.prepend("")
            .compactMap({ $0 })
            .withUnretained(self)
            .flatMap { (vm, searchQuery) -> AnyPublisher<[DiffableCollectionSection]?, Never> in
             
                guard !searchQuery.isEmpty else { return .just(nil) }
                
                let news: AnyPublisher<DiffableCollectionSection?, Never> = vm.newsSearchService.newsSearch(query: searchQuery, page: 0, limit: 10, refresh: true, topic: nil)
                    .catchWithErrorWithNever(errHandle: vm.errorMessage, withErr: URLSessionError.invalidResponse)
                    .withUnretained(self)
                    .map { (vm, newsResult) -> DiffableCollectionSection? in
                        guard let data = newsResult.data, !data.isEmpty else { return nil }
                        return vm.setupSearchedNews(data, search: searchQuery)
                    }
                    .eraseToAnyPublisher()
                
                let searchResult = vm.tickerSearchService.search(query: searchQuery)
                    .catchWithErrorWithNever(errHandle: vm.errorMessage, withErr: URLSessionError.invalidResponse)
                    .withUnretained(self)
                    .map { (vm, searchResult) -> DiffableCollectionSection? in
                        guard let data = searchResult.data, !data.isEmpty else { return nil }
                        return vm.setupSearchedTickers(data)
                    }
                    .eraseToAnyPublisher()
                
                return Publishers.CombineLatest(news, searchResult)
                    .map { [$0, $1].compactMap({ $0 }) }
                    .eraseToAnyPublisher()
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
        
        let sections = Publishers.Merge(placeHolderSection, search)
            .eraseToAnyPublisher()
        
        return .init(section: sections)
        
    }
    
    private func simpleRowLayout(addTrailingInset: Bool) -> NSCollectionLayoutSection {
        let inset: NSDirectionalEdgeInsets = addTrailingInset ? .sectionInsets : .init(top: .standardColumnSpacing, leading: .zero, bottom: .standardColumnSectionSpacing, trailing: .zero)
        let sectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44), insets: .section(inset), spacing: .appVerticalPadding)
            .addHeader()
        return sectionLayout
    }
    
    
    // MARK: - Coin Of the Day
    
    private func setupCoinOfTheDay(_ coin: CoinOfTheDay) -> DiffableCollectionSection {
        let sectionLayout = simpleRowLayout(addTrailingInset: false)
        
        let callback: Callback = { [weak self] in
            self?.navigation.send(.toTicker(ticker: coin.symbol, name: coin.name))
        }
        
        let coin = DiffableCollectionItem<TickerCardCellView>(.init(ticker: coin.symbol, name: coin.name, action: callback))
        
        let header = CollectionSectionHeader(.init(label: Section.coinOfTheDay.name))
        
        return .init(Section.coinOfTheDay.rawValue, cells: [coin], header: header, sectionLayout: sectionLayout)
    }
    
    
    // MARK: - Coins Of the Day
    
    private func setupCoinsOfTheDay(_ coinList: [LunarCoinInfo]) -> DiffableCollectionSection {
        let sectionLayout = simpleRowLayout(addTrailingInset: false)
        
        let cells = coinList.limit(to: 4).map { coin in
            let callback: Callback = { [weak self] in
                self?.navigation.send(.toTicker(ticker: coin.symbol, name: coin.name))
            }
            return DiffableCollectionItem<TickerCardCellView>(.init(ticker: coin.symbol, name: coin.name, action: callback))
        }
        
        let header = CollectionSectionHeader(.init(label: Section.trendingCoins.name))
        
        return .init(Section.trendingCoins.rawValue, cells: cells, header: header, sectionLayout: sectionLayout)
    }
    
    
    // MARK: - Recently Searched Coins
    
    private func setupRecentlySearchedCoins() -> DiffableCollectionSection? {
        let recentlySearchedTickers: [String] = TickerUserDefaultService.shared.getRecentlySearchedTickers()
        
        guard !recentlySearchedTickers.isEmpty else { return nil }
            
        let sectionLayout = simpleRowLayout(addTrailingInset: true)
                    
        let cells = recentlySearchedTickers.limit(to: 4).map { coin in
            DiffableCollectionItem<RecentTickerSearchView>(.init(ticker: coin, action: nil))
        }
        
        let header = CollectionSectionHeader(.init(label: Section.recentlySearch.name, addHorizontalInset: false))
        
        return .init(Section.recentlySearch.rawValue, cells: cells, header: header, sectionLayout: sectionLayout)
    }
        
    
    // MARK: - Searched Tickers
    
    private func setupSearchedTickers(_ tickers: [TickerInfo]) -> DiffableCollectionSection {
        let layout = simpleRowLayout(addTrailingInset: false)
        
        let viewMoreCallback: Callback = {
            print("(DEBUG) View More Clicked")
        }
        
        let sectionHeader = CollectionSectionHeader(.init(label: Section.tickers.name, accessory: .viewMore("View More", viewMoreCallback)))
        
        let cells = tickers.limit(to: 4).map { ticker in
            let action = { [weak self] in
                self?.navigation.send(.toTicker(ticker: ticker.symbol, name: ticker.name))
            }
            
            return DiffableCollectionItem<TickerCardCellView>(.init(ticker: ticker.symbol, name: ticker.name))
        }
        
        return .init(Section.tickers.rawValue, cells: cells, header: sectionHeader, sectionLayout: layout)
    }
    
    
    // MARK: - Searched News
    
    private func setupSearchedNews(_ news: [NewsModel], search: String) -> DiffableCollectionSection {
        let layout = simpleRowLayout(addTrailingInset: true)
        
        let viewMoreCallback: Callback = { [weak self] in
             self?.navigation.send(.toNewsFeed(news, search))
        }
        let sectionHeader = CollectionSectionHeader(.init(label: Section.news.name, accessory: .viewMore("View More", viewMoreCallback), addHorizontalInset: false))
        
        let cells = news.limit(to: 4).indices.map {
            let news = news[$0]
            let action: Callback = { [weak self] in
                self?.navigation.send(.toNews(news))
            }
            return DiffableCollectionItem<NewsView>(.init(model: news, isFirst: $0 == 0, isLast: $0 == 3, action: action))
        }
        
        return .init(Section.news.rawValue, cells: cells, header: sectionHeader, sectionLayout: layout)
    }
}
