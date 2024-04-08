//
//  TickerDetailViewModel.swift
//  DekryptUI_Example
//
//  Created by Krishna Venkatramani on 21/02/2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import KKit
import DekryptUI
import SwiftUI
import Combine
import DekryptService

public enum TickerError: StandardError {
    case tickerError
}

public class TickerDetailViewModel {
    typealias ItemReloadBody = (Section, Int, DiffableCollectionCellProvider, Bool)
    
    enum Section: Int {
        case price = 1, metrics, news, video, event, sentiment
        
        var name: String {
            switch self {
            case .price:
                return "Price"
            case .metrics:
                return "Metrics"
            case .news:
                return "News"
            case .video:
                return "Videos"
            case .sentiment:
                return "Sentiments"
            case .event:
                return "Events"
            }
        }
    }

    enum Navigation {
        case toNews(NewsModel)
        case toEvent(EventModel)
    }
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
        let navigation: AnyPublisher<Navigation, Never>
        let reloadFavorite: AnyPublisher<ItemReloadBody, Never>
        let errorMessage: AnyPublisher<String?, Error>
    }
    
    @Published private var isFavorite: TickerInfoView.State = .notFavorite
    @Published private var selectedTimeLine: PriceTimeline = .sevenDays
    private var errorMessage: PassthroughSubject<String?, Error> = .init()
    private var navigation: PassthroughSubject<Navigation, Never> = .init()
    private let currentSentimentPage: PassthroughSubject<Int, Never> = .init()
    private let ticker: String
    private let tickerName: String
    private let tickerService: TickerServiceInterface
    private let eventService: EventServiceInterface
    
    init(tickerService: TickerServiceInterface, eventService: EventServiceInterface, ticker: String, tickerName: String) {
        self.tickerService = tickerService
        self.eventService = eventService
        self.ticker = ticker
        self.tickerName = tickerName
    }
    
    func transform() -> Output {
        
        // Ticker Info
        let tickerInfo = tickerService.fetchTickerDetail(ticker: tickerName, refresh: false)
            .catchWithErrorWithNever(errHandle: errorMessage, withErr: TickerError.tickerError)
            .compactMap(\.data)
            .eraseToAnyPublisher()
        
        // News
        let news = tickerService.fetchNews(ticker: ticker, page: 1, limit: 20, refresh: false)
            .catchWithErrorWithNever(errHandle: errorMessage, withErr: TickerError.tickerError)
            .compactMap(\.data)
            .eraseToAnyPublisher()
        
        // Videos
        let videos = tickerService.fetchVideos(ticker: [ticker], limit: 10, page: 1, refresh: false)
            .catchWithErrorWithNever(errHandle: errorMessage, withErr: TickerError.tickerError)
            .compactMap(\.data)
            .eraseToAnyPublisher()
        
        // Event
        let event = tickerService.fetchEvent(ticker: ticker, page: 1, limit: 10, refresh: false)
            .catchWithErrorWithNever(errHandle: errorMessage, withErr: TickerError.tickerError)
            .compactMap(\.data)
            .eraseToAnyPublisher()
        
        let isFavorite = $isFavorite.eraseToAnyPublisher()
        
        let sections: AnyPublisher<[DiffableCollectionSection], Never> = Publishers.CombineLatest4(tickerInfo, news, videos, event)
            .combineLatest(isFavorite.first())
            .map({ ($0.0, $0.1, $0.2, $0.3, $1) })
            .withUnretained(self)
            .compactMap { (weakSelf, model) -> [DiffableCollectionSection]? in
                let sentiments = (model.0.sentiment ?? .init(total: nil, timeline: nil))
                return weakSelf.setupTickerInfo(ticker: model.0.ticker, sentiment: sentiments, news: model.1, videos: model.2, events: model.3, isFavorite: model.4)
            }
            .eraseToAnyPublisher()
        
        // Reload Header when favorite
        
        let reloadHeader: AnyPublisher<ItemReloadBody, Never> = $isFavorite
            .dropFirst(1)
            .withLatestFrom(tickerInfo.compactMap(\.ticker).eraseToAnyPublisher())
            .withUnretained(self)
            .compactMap { (vm, data) -> DiffableCollectionCellProvider? in
                let (isFavorite, ticker) = data
                let header = DiffableCollectionItem<TickerInfoView>(.init(ticker: ticker, isFavorite: isFavorite, addFavorite: vm.addFavorite))
                return header
            }
            .map({ (Section.price, 0, $0, false) })
            .eraseToAnyPublisher()
        
        return .init(section: sections, navigation: navigation.eraseToAnyPublisher(), reloadFavorite: reloadHeader, errorMessage: errorMessage.eraseToAnyPublisher())
    }
    
    private func setupTickerInfo(ticker: DekryptService.TickerModel?, sentiment: SentimentForTicker?, news: [NewsModel], videos: [VideoModel], events: [EventModel], isFavorite: TickerInfoView.State) -> [DiffableCollectionSection] {
        
        let priceSection = setupPriceChartSection(ticker: ticker, isFavorite: isFavorite)
        
        var sentimentSection: DiffableCollectionSection? = nil
        if let timeline = sentiment?.timeline {
            sentimentSection = setupSentimentSection(total: sentiment?.total, sentiment: Array(timeline.values))
        }
        
        // Ticker Summary
        let tickerSummarySection = setupSummarySection(ticker: ticker)
        // News Section
        let newsSection = setupNewsSection(news: news)
        // Video Section
        let videoSection = setupVideoSection(videos: videos)
        // Event Section
        let eventSection = setupEventSection(events: events)
        
        return [priceSection, tickerSummarySection, sentimentSection, newsSection, videoSection, eventSection].compactMap({ $0 })
        // return [priceSection, tickerSummarySection, sentimentSection, newsSection, videoSection].compactMap({ $0 })
    }
    
    
    // MARK: - Price Chart
    
    private func setupPriceChartSection(ticker: TickerModel?, isFavorite: TickerInfoView.State) -> DiffableCollectionSection? {
        
        let sectionLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(200), insets: .section(.sectionInsets), spacing: 32)
        
        var cells: [DiffableCollectionCellProvider] = []
        
        cells.append(DiffableCollectionItem<TickerInfoView>(.init(ticker: .init(id: nil, symbol: self.ticker, name: tickerName, hashingAlgorithms: nil, description: nil, image: .init(thumb: self.ticker.logoStr, small: self.ticker.logoStr, large: self.ticker.logoStr), marketData: nil, marketCapRank: nil, communityScore: nil, liquidityScore: nil), isFavorite: isFavorite, addFavorite: addFavorite)))

        guard let ticker else {
            cells.append(DiffableCollectionItem<TickerNoInfoView>(.init(ticker: tickerName)))
            return .init(Section.price.rawValue, cells: cells, sectionLayout: sectionLayout)
        }
        
        if let sparkline = ticker.marketData {
            cells.append(DiffableCollectionCellView<TickerPriceView>(model: .init(marketData: sparkline, selectedTimeline: $selectedTimeLine.eraseToAnyPublisher())))
        }
        
        
        let timelineSegment = DiffableCollectionItem<FilterView>(.init(filterCases: PriceTimeline.allCases, selectedCase: PriceTimeline.sevenDays, addHorizontalPadding: false, selectedFilterHandler: { [weak self] filter in
            guard let self, let selectedFilter = filter as? PriceTimeline else { return }
            self.selectedPriceTimeLine(selectedFilter)
        }))
        
        cells.append(timelineSegment)
        
        
        
        return DiffableCollectionSection(Section.price.rawValue, cells: cells, sectionLayout: sectionLayout)
    }
    
    
    // MARK: - Sentiement Chart
        
    private func setupSentimentSection(total: SentimentModel?, sentiment: [SentimentModel]?) -> DiffableCollectionSection? {
        guard let total, let sentiment, !sentiment.isEmpty else { return nil }
        
        let sentimentCell = DiffableCollectionCellView<SentimentBarChartCard>(model: .init(title: "Sentiment this Month", sentiment: sentiment))
        
        let totalSentimentCell = DiffableCollectionCellView<SentimentDonutChartCard>(model: .init(sentiment: total, reload: false, showCount: true, title: "Total Sentiment"))
        
        let sectionHeader = CollectionSupplementaryView<SectionHeader>(.init(label: Section.sentiment.name, addHorizontalInset: true))
        
        let insets: NSDirectionalEdgeInsets = .init(top: .standardColumnSpacing, leading: .zero, bottom: .appVerticalPadding.half, trailing: .zero)
        
        let sectionLayout = NSCollectionLayoutSection.singleRowLayout(width: .fractionalWidth(1), height: .absolute(440), insets: .section(insets), spacing: .zero)
            .addHeader()
            .addFooter(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44.0)))
        
        sectionLayout.orthogonalScrollingBehavior = .groupPaging
        
        let sectionFooter = CollectionSupplementaryView<SentimentPageControl>(.init(count: 2, startIndex: 0, updateIndex: currentSentimentPage.eraseToAnyPublisher()))
        
        sectionLayout.visibleItemsInvalidationHandler = { [weak self] items, point, environment in
            let x = point.x
            let width = environment.container.contentSize.width
            let currentIndex = (x/width).rounded(.down)
            self?.currentSentimentPage.send(Int(currentIndex))
        }
        
        let section = DiffableCollectionSection(Section.sentiment.rawValue, cells: [totalSentimentCell, sentimentCell], header: sectionHeader, footer: sectionFooter, sectionLayout: sectionLayout)
        
        return section
    }
    
    
    // MARK: - Ticker Info Section
    
    private func setupSummarySection(ticker: TickerModel?) -> DiffableCollectionSection? {
        
        guard let ticker else { return nil }
        
        let tickerSummaryHeader = CollectionSupplementaryView<SectionHeader>(.init(label: Section.metrics.name, addHorizontalInset: false))
        let tickerSummaryLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44), insets: .section(.init(vertical: .standardColumnSpacing, horizontal: .appHorizontalPadding)))
            .addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44.0)))
        
        return DiffableCollectionSection(Section.metrics.rawValue, cells: [DiffableCollectionCellView<TickerSummaryView>(model: ticker)], header: tickerSummaryHeader, sectionLayout: tickerSummaryLayout)
    }
    
    
    // MARK: - News Section
    
    private func setupNewsSection(news: [NewsModel]) -> DiffableCollectionSection {
        let newsSectionHeader = CollectionSectionHeader(.init(label: Section.news.name, addHorizontalInset: false))
        let newsSectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0),
                                                                             height: .estimated(44),
                                                                             insets: .sectionInsets)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44.0)))
        
        let newsCells = news
            .limit(to: 4)
            .indices
            .map { idx in
                let action = {
                    self.navigation.send(.toNews(news[idx]))
                }
                return DiffableCollectionItem<NewsView>(.init(model: news[idx], isFirst: idx == 0, isLast: idx == 3, action: action))
            }
        
        return DiffableCollectionSection(Section.news.rawValue, cells: newsCells, header: newsSectionHeader, sectionLayout: newsSectionLayout)
    }
    
    
    // MARK: - Video Section
    
    private func setupVideoSection(videos: [VideoModel]) -> DiffableCollectionSection {
        let videoSectionHeader = CollectionSectionHeader(.init(label: Section.video.name, addHorizontalInset: false))
        
        let interItemSpacing: CGFloat = .appHorizontalPadding
        let width = CGFloat.totalWidth.half - interItemSpacing
        let height = width/0.75
        
        let videoSectionLayout = NSCollectionLayoutSection.twoGrid(interItemSpacing: .appVerticalPadding.half, height: height, inset: .sectionInsets)
            .addHeader()
        
        let videoCells = videos
            .limit(to: 3)
            .indices
            .map { idx in
                let video = videos[idx]
                return DiffableCollectionItem<VideoCard>(.init(model: video, size: .small))
            }
        
        return .init(Section.video.rawValue, cells: videoCells, header: videoSectionHeader, sectionLayout: videoSectionLayout)
    }
    
    
    // MARK: - Event Section
    
    private func setupEventSection(events: [EventModel]) -> DiffableCollectionSection {
        let eventSectionHeader = CollectionSectionHeader(.init(label: Section.event.name, addHorizontalInset: false))
        let layout = NSCollectionLayoutSection.singleRowLayout(width: .absolute(225), height: .absolute(250), insets: .sectionInsets,  spacing: .appHorizontalPadding)
            .addHeader()
        
        layout.orthogonalScrollingBehavior = .groupPaging
        
        let eventCells = events
            .limit(to: 3)
            .map { event in
                let action: Callback = { [weak self] in
                    self?.navigation.send(.toEvent(event))
                    
                }
                return DiffableCollectionItem<EventCard>(.init(event: event, action: action))
            }
        
        return .init(Section.event.rawValue, cells: eventCells, header: eventSectionHeader, sectionLayout: layout)
        
    }
    
    private func addFavorite() {
        DispatchQueue.main.async {
            self.isFavorite = .favorite
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
            guard let self else { return }
            self.isFavorite = .notFavorite
        }
    }
    
    private func selectedPriceTimeLine(_ selected: PriceTimeline) {
        print("(DEBUG) selected: ", selected.name)
        self.selectedTimeLine = selected
    }
    
}
