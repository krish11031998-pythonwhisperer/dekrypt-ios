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
            }
        }
    }
    
    enum Navigation {
        case toNews(NewsModel)
        case toTicker(ticker: String, name: String)
    }
    
    private(set) var searchParam: PassthroughSubject<String?, Never> = .init()
    private(set) var navigation: PassthroughSubject<Navigation, Never> = .init()
    private let searchService: TickerServiceInterface
    private let lunarService: LunarCrushServiceInterface
    private let errorMessage: PassthroughSubject<String?, Error> = .init()
    
    init(searchService: TickerServiceInterface, lunarService: LunarCrushServiceInterface) {
        self.searchService = searchService
        self.lunarService = lunarService
    }
    
    func transform() -> Output {
        let placeHolderSection = Publishers.Zip(lunarService.fetchCoinList(), lunarService.fetchCoinOfTheDay())
            .catchWithErrorWithNever(errHandle: errorMessage, withErr: URLSessionError.invalidResponse)
            .withUnretained(self)
            .map { (vm, coin) in
                let (coinList, coinOfTheDay) = coin
                return [vm.setupCoinOfTheDay(coinOfTheDay), vm.setupCoinsOfTheDay(coinList)].compactMap { $0 }
            }
            .eraseToAnyPublisher()
        
        let search: AnyPublisher<[DiffableCollectionSection]?, Never> = searchParam
            .prepend("")
            .compactMap({ $0 })
            .withUnretained(self)
            .flatMap { (vm, searchQuery) -> AnyPublisher<[DiffableCollectionSection]?, Never> in
             
                guard !searchQuery.isEmpty else { return .just(nil) }
                
                let news: AnyPublisher<DiffableCollectionSection?, Never> = vm.searchService.fetchNews(ticker: searchQuery, page: 0, limit: 10, refresh: true)
                    .catchWithErrorWithNever(errHandle: vm.errorMessage, withErr: URLSessionError.invalidResponse)
                    .withUnretained(self)
                    .map { (vm, newsResult) -> DiffableCollectionSection? in
                        guard let data = newsResult.data, !data.isEmpty else { return nil }
                        return vm.setupSearchedNews(data)
                    }
                    .eraseToAnyPublisher()
                
                let searchResult = vm.searchService.search(query: searchQuery)
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
            .eraseToAnyPublisher()
        
        let sections = Publishers.CombineLatest(placeHolderSection, search)
            .map {
                if let searchResult = $1 {
                    return searchResult
                } else {
                    return $0
                }
            }
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
    
    private func setupCoinsOfTheDay(_ coinList: LunarCoinList) -> DiffableCollectionSection {
        let sectionLayout = simpleRowLayout(addTrailingInset: false)
        
        let cells = coinList.data.limit(to: 4).map { coin in
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
        
        let header = CollectionSectionHeader(.init(label: Section.trendingCoins.name))
        
        return .init(Section.trendingCoins.rawValue, cells: cells, header: header, sectionLayout: sectionLayout)
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
    
    private func setupSearchedNews(_ news: [NewsModel]) -> DiffableCollectionSection {
        let layout = simpleRowLayout(addTrailingInset: true)
        
        let viewMoreCallback: Callback = {
            // self.navigation.send(.toNews(news))
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
