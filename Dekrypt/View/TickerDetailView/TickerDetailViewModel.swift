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
        case videos([VideoModel], VideoModel)
        case toHabit
        case showAlertForOnboarding
    }
    
    struct Input {
        let addFavoritePublisher: AnyPublisher<Void, Never>
        let addHabitPublisher: AnyPublisher<Void, Never>?
    }
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
        let navigation: AnyPublisher<Navigation, Never>
        let addedFavorite: AnyPublisher<Bool, Never>
        let errorMessage: AnyPublisher<String?, Error>
    }
    
    @Published private var isFavorite: TickerInfoView.State = .notFavorite
    @Published private var selectedTimeLine: PriceTimeline = .sevenDays
    private var errorMessage: PassthroughSubject<String?, Error> = .init()
    private var navigation: PassthroughSubject<Navigation, Never> = .init()
    private let currentSentimentPage: PassthroughSubject<Int, Never> = .init()
    private let refreshData: CurrentValueSubject<Bool, Never> = .init(false)
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
    
    func transform(input: Input) -> Output {
        
        let isFavorite = $isFavorite.share().eraseToAnyPublisher()

        let addedToWatchlist = isFavorite
            .combineLatest(AppStorage.shared.userPublisher.compactMap({ $0 }))
            .withUnretained(self)
            .flatMap { (vm, model) in
                let (isFavorite, user) = model
                return UserService.shared.addAssetToWatchlist(uid: user.uid, asset: vm.ticker)
            }
            .eraseToAnyPublisher()
        
        let sections: AnyPublisher<[DiffableCollectionSection], Never> = Publishers.CombineLatest(AppStorage.shared.userPublisher
            .removeDuplicates(), refreshData.eraseToAnyPublisher())
            .withUnretained(self)
            .flatMap { (vm, model) -> AnyPublisher<TickerDetailModel, Never> in
                let (user, refresh) = model
                return vm.fetchTickerDetail(user: user, refresh: refresh)
            }
            .combineLatest(isFavorite)
            .withUnretained(self)
            .map { (vm, model) in
                vm.setupTickerInfo(tickerDetail: model.0, isFavorite: model.1)
            }
            .eraseToAnyPublisher()
        
        
        let addFavoriteSharePublisher = input.addFavoritePublisher
            .withLatestFrom(AppStorage.shared.userPublisher)
            .map { _, user in user }
            .share()
        
        let navToOnboardingWhenUserIsNotLoggedIn = addFavoriteSharePublisher
            .filter { $0 == nil }
            .map { _ in Navigation.showAlertForOnboarding }
            .eraseToAnyPublisher()
        
        let addToWatchlist = addFavoriteSharePublisher
            .compactMap({ $0 })
            .withUnretained(self)
            .flatMap { (vm, user) in
                if let watching = user.watching, watching.contains(vm.ticker) {
                    UserService.shared.removeAssetToWatchlist(uid: user.uid, asset: vm.ticker)
                        .map { _ in false }
                        .replaceError(with: true)
                        .eraseToAnyPublisher()
                } else {
                    UserService.shared.addAssetToWatchlist(uid: user.uid, asset: vm.ticker)
                        .map { _ in true }
                        .replaceError(with: false)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
        
        // Reload Header when favorite
        
        let navigationPublisher: AnyPublisher<Navigation, Never>
        if let addHabitPublisher = input.addHabitPublisher {
            navigationPublisher = Publishers.Merge3(navigation.eraseToAnyPublisher(), addHabitPublisher.map { _ in Navigation.toHabit }.eraseToAnyPublisher(), navToOnboardingWhenUserIsNotLoggedIn)
                .eraseToAnyPublisher()
        } else {
            navigationPublisher = navigation.eraseToAnyPublisher()
        }
        
        
        return .init(section: sections,
                     navigation: navigationPublisher, addedFavorite: addToWatchlist,
                     errorMessage: errorMessage.eraseToAnyPublisher())
    }
    
    private func setupTickerInfo(tickerDetail: DekryptService.TickerDetailModel, isFavorite: TickerInfoView.State) -> [DiffableCollectionSection] {
        
        var sections: [DiffableCollectionSection] = []
        
        if let tickerSection = setupPriceChartSection(ticker: tickerDetail.ticker, isFavorite: isFavorite) {
            sections.append(tickerSection)
        }
        
        if let summary = setupSummarySection(ticker: tickerDetail.ticker) {
            sections.append(summary)
        }
        
        if let timeline = tickerDetail.sentiment?.timeline,
           let sentimentSection = setupSentimentSection(total: tickerDetail.sentiment?.total, sentiment: Array(timeline.values))
        {
            sections.append(sentimentSection)
        }
        
        if let news = tickerDetail.news {
            sections.append(setupNewsSection(news: news))
        }
        
        if let videos = tickerDetail.videos {
            sections.append(setupVideoSection(videos: videos))
        }
        
        if let events = tickerDetail.events {
            sections.append(setupEventSection(events: events))
        }
        
        return sections
    }
    
    
    // MARK: - FetchTickerDetail
    
    private func fetchTickerDetail(user: UserModel?, refresh: Bool) -> AnyPublisher<TickerDetailModel, Never> {
        tickerService.fetchTickerDetail(ticker: ticker, isPro: user?.isPro ?? false, refresh: refresh)
            .compactMap(\.data)
            .catch({ err -> AnyPublisher<TickerDetailModel, Never> in
                print("(ERROR) err: ", err.localizedDescription)
                return .just(TickerDetailModel(ticker: nil, sentiment: nil, videos: nil, news: nil, events: nil))
            })
            .eraseToAnyPublisher()
    }
    
    
    // MARK: - Price Chart
    
    private func setupPriceChartSection(ticker: TickerModel?, isFavorite: TickerInfoView.State) -> DiffableCollectionSection? {
        
        let sectionLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(200), insets: .section(.sectionInsets), spacing: 32)
        
        var cells: [DiffableCollectionCellProvider] = []
        
        cells.append(DiffableCollectionItem<TickerInfoView>(.init(ticker: .init(id: nil, symbol: self.ticker, name: tickerName, hashingAlgorithms: nil, description: nil, image: .init(thumb: self.ticker.logoStr, small: self.ticker.logoStr, large: self.ticker.logoStr), marketData: nil, marketCapRank: nil, communityScore: nil, liquidityScore: nil), isFavorite: isFavorite)))

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
        
        let action: (VideoModel) -> Callback = { video in
            return { [weak self] in
                self?.navigation.send(.videos(videos, video))
            }
        }
        
        let videoCells = videos
            .limit(to: 4)
            .indices
            .map { idx in
                let video = videos[idx]
                return DiffableCollectionItem<VideoCard>(.init(model: video, size: .small, action: action(video)))
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
    
    
    // MARK: - Refresh
    
    public func refresh() {
        refreshData.send(true)
    }
}
