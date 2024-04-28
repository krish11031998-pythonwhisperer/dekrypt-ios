//
//  HomeViewModel.swift
//  DekryptUI
//
//  Created by Krishna Venkatramani on 21/01/2024.
//

import KKit
import Combine
import DekryptUI
import DekryptService
import UIKit

class HomeViewModel {
   
    struct Output {
        let sections: AnyPublisher<[DiffableCollectionSection], Never>
        let navigation: AnyPublisher<Navigation, Never>
    }
    
    enum Section: Int, Hashable {
        case news = 0, headline, event, tickerMentions, video, insights
        
        var name: String {
            switch self {
            case .news:
                return "News"
            case .headline:
                return "Headlines"
            case .event:
                return "Events"
            case .tickerMentions:
                return "Ticker Mentions"
            case .video:
                return "Video"
            case .insights:
                return "Insights"
            }
        }
    }
    
    enum Navigation {
        case toNews(NewsModel)
        case toEvent(EventModel)
        case toTickers([MentionTickerModel])
        case toTickerDetail(MentionTickerModel)
        case toVideo([VideoModel])
        case toAllNews([NewsModel])
        case toAllInsights([InsightDigestModel])
        case toInsight(InsightDigestModel)
    }
    

    private let socialService: SocialHighlightServiceInterface
    private let videoService: VideoServiceInterface
    private let errorMessage: PassthroughSubject<String, Never> = .init()
    private let navigation: PassthroughSubject<Navigation, Never> = .init()
    private let refreshData: CurrentValueSubject<Bool, Never> = .init(false)
    
    init(socialService: SocialHighlightServiceInterface, videoService: VideoServiceInterface) {
        self.socialService = socialService
        self.videoService = videoService
    }
    
    
    func transform() -> Output {
        
        let refreshPublisher = refreshData
            .removeDuplicates()
            .filter({ $0 })
            .prepend(true)
            .eraseToAnyPublisher()
        
        let sections = Publishers.CombineLatest(AppStorage.shared.userPublisher, refreshPublisher)
            .withUnretained(self)
            .flatMap { (vm, model) in
                let (user, refresh) = model
                return Publishers.CombineLatest3(vm.fetchHighlights(refresh: refresh), vm.fetchVideos(refresh: refresh), vm.fetchInsights(refresh: refresh))
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.global(qos: .background))
            .map { [weak self] (hightlights, videos, insights) -> [DiffableCollectionSection] in
                guard let self else { return [] }
                return self.buildSections(highlight: hightlights, videos: videos, insights: insights)
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self else { return }
                if self.refreshData.value {
                    self.refreshData.send(false)
                }
            })
            .eraseToAnyPublisher()
        
        return .init(sections: sections, navigation: navigation.eraseToAnyPublisher())
    }
    
    
    // MARK: - Fetch Highlights
    
    private func fetchHighlights(refresh: Bool) -> AnyPublisher<SocialHighlightModel, Never> {
        socialService.fetchSocialHighlight(refresh: refresh)
            .compactMap(\.data)
            .replaceError(with: .init(news: nil, events: nil, topMention: nil, headlines: nil))
            .eraseToAnyPublisher()
    }
    
    
    // MARK: - Fetch Video
    
    private func fetchVideos(refresh: Bool) -> AnyPublisher<[VideoModel], Never> {
        videoService.fetchVideo(entity: nil, page: 1, limit: 10)
            .compactMap(\.data)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    
    // MARK: - Fetch Insight
    
    private func fetchInsights(refresh: Bool) -> AnyPublisher<[InsightDigestModel], Never> {
        socialService.fetchInsightDigest(page: 1, limit: 10)
            .compactMap(\.data)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    private func buildSections(highlight: SocialHighlightModel, videos: [VideoModel], insights: [InsightDigestModel]) -> [DiffableCollectionSection] {
        var section: [DiffableCollectionSection] = []
  
        if let headlines = highlight.headlines {
            section.append(headlineSection(headlines: headlines))
        }
        
        if let news = highlight.news {
            section.append(newsSection(news: news))
        }
        
        if AppStorage.shared.user?.isPro ?? false {
            if let events = highlight.events {
                section.append(eventSection(events: events))
            }
        }
        
        
        if let mention = highlight.topMention {
            section.append(tickerMentionSection(mention: mention))
        }
        
        section.append(videoSection(videos: videos))
        
        if AppStorage.shared.user?.isPro ?? false  {
            section.append(insightsSection(insights: insights))
        }
        
        return section
    }
    
    
    // MARK: - News Section
    
    private func newsSection(news newsList: [NewsModel]) -> DiffableCollectionSection {
        
        let shortNewsList = newsList.limit(to: 10)
        let cells = shortNewsList.indices.map { idx in
            let news = shortNewsList[idx]
            let cellModel = NewsView.Model(model: news, isFirst: idx == 0, isLast: shortNewsList.count - 1 == idx) { [weak self] in
                self?.navigation.send(.toNews(news))
            }
            return DiffableCollectionItem<NewsView>(cellModel)
        }
        
        let action: Callback = { [weak self] in
            guard let self else { return }
            self.navigation.send(.toAllNews(newsList))
        }
        
        let sectionHeader = CollectionSectionHeader(.init(label: Section.news.name, accessory: .viewMore("View More", action), addHorizontalInset: false))
        
        let sectionLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1), height: .estimated(100), insets: .sectionInsets, spacing: .appVerticalPadding)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)))
        
        return .init(Section.news.rawValue, cells: cells, header: sectionHeader, sectionLayout: sectionLayout)
    }
    
    
    // MARK: - Headline Section
    
    private func headlineSection(headlines: [TrendingHeadlinesModel]) -> DiffableCollectionSection {
        let cells = headlines.compactMap { headline -> (any DiffableCollectionCellProviderType)? in
            guard headline.news?.imageUrl != nil else { return nil }
            return DiffableCollectionItem<TrendingHeadlineNews>(.init(headline: headline, action: { [weak self] in
                guard let news = headline.news else { return }
                self?.navigation.send(.toNews(news))
            }))
        }
        
        let sectionHeader = CollectionSectionHeader(.init(label: Section.headline.name, addHorizontalInset: false))
        
        let sectionLayout: NSCollectionLayoutSection = .singleRowLayout(width: .absolute(275), height: .absolute(325), insets: .sectionInsets, spacing: .appHorizontalPadding)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)))
        
        sectionLayout.orthogonalScrollingBehavior = .groupPaging
        
        return .init(Section.headline.rawValue, cells: cells, header: sectionHeader, sectionLayout: sectionLayout)
    }
    
    
    // MARK: - Event Section
    
    private func eventSection(events: [EventModel]) -> DiffableCollectionSection {
        
        let cells = events.map { event in
            DiffableCollectionItem<EventCardView>(.init(event: event, action: { [weak self] in
                self?.navigation.send(.toEvent(event))
            }))
        }
        let ratio: CGFloat = 375/310
        let width: CGFloat = .totalWidth
        let sectionHeader = CollectionSectionHeader(.init(label: Section.event.name, addHorizontalInset: false))
        let height: CGFloat = ratio * width
        let sectionLayout: NSCollectionLayoutSection = .singleRowLayout(width: .absolute(0.8 * .totalWidth), height: .absolute(height),
                                                                        insets: .sectionInsets, spacing: .appHorizontalPadding)
            .addHeader()
        
        sectionLayout.orthogonalScrollingBehavior = .groupPagingCentered
        
        return .init(Section.event.rawValue, cells: cells, header: sectionHeader, sectionLayout: sectionLayout)
        
    }
    
    
    // MARK: - Ticker Mentions
    
    private func tickerMentionSection(mention: [MentionTickerModel]) -> DiffableCollectionSection {
        
        let action: MentionTickerCallback = { [weak self] ticker in
            guard let self else { return }
            self.navigation.send(.toTickerDetail(ticker))
        }
        
        // Top Mention
        let topMentions = mention.sorted(by: { $0.totalMentions > $1.totalMentions }).limit(to: 5)
        
        let top = DiffableCollectionItem<TopMentionTickerView>(.init(tickers: topMentions, title: "Top", action: action))
        
        // Positive mention
        let positiveMentions = mention.sorted(by: { $0.sentimentScore > $1.sentimentScore }).limit(to: 5)
         
        let positive = DiffableCollectionItem<TopMentionTickerView>(.init(tickers: positiveMentions, title: "Positive", action: action))
        
        // Negative mention
        let negativeMentions = mention.sorted(by: { $0.sentimentScore < $1.sentimentScore }).limit(to: 5)
         
        let negative = DiffableCollectionItem<TopMentionTickerView>(.init(tickers: negativeMentions, title: "Negative", action: action))
        
        let layout = NSCollectionLayoutSection.singleRowLayout(width: .absolute(.totalWidth * 0.85), height: .estimated(150), insets: .sectionInsets,  spacing: .appHorizontalPadding)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)))
        
        layout.orthogonalScrollingBehavior = .groupPaging
        
        let callback: Callback = { [weak self] in
            self?.navigation.send(.toTickers(mention))
        }
        
        let sectionHeader = CollectionSectionHeader(.init(label: Section.tickerMentions.name, accessory: .viewMore("View More", callback), addHorizontalInset: false))
        
        return DiffableCollectionSection(Section.tickerMentions.rawValue, cells: [top, positive, negative], header: sectionHeader, sectionLayout: layout)
    }
    
    
    // MARK: - Video Section
    
    private func videoSection(videos: [VideoModel]) -> DiffableCollectionSection {
        
        let inset: NSDirectionalEdgeInsets = .sectionInsets
        let interItemSpacing: CGFloat = .appHorizontalPadding.half
        let width = CGFloat.totalWidth.half - interItemSpacing.half - .appHorizontalPadding
        let height = width/0.75

        
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .absolute(height))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(height)), repeatingSubitem: item, count: 2)
        
        group.interItemSpacing = .fixed(interItemSpacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = interItemSpacing
        section.contentInsets = inset
        section.addHeader()
       
        
        let cells = videos.limit(to: 4).map { video in
            DiffableCollectionItem<VideoCard>(.init(model: video, size: .small) { [weak self] in
                self?.navigation.send(.toVideo(videos))
            })
        }
        
        let header = CollectionSectionHeader(.init(label: Section.video.name, addHorizontalInset: false))
        
        return .init(Section.video.rawValue, cells: cells, header: header, sectionLayout: section)
        
    }
    
    
    // MARK: - Insights
    
    private func insightsSection(insights: [InsightDigestModel]) -> DiffableCollectionSection {
        
        let layout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .absolute(325), insets: .sectionInsets, spacing: .appHorizontalPadding).addHeader()
        
        //layout.orthogonalScrollingBehavior = .groupPaging
        
        let viewMoreCallBack: Callback = { [weak self] in
            self?.navigation.send(.toAllInsights(insights))
        }
        
        let insightCallback: (InsightDigestModel) -> Callback = { [weak self] insight in
            return {
                self?.navigation.send(.toInsight(insight))
            }
        }
        
        let sectionHeader = CollectionSectionHeader(.init(label: "Insights", accessory: .viewMore("View more", viewMoreCallBack), addHorizontalInset: false))
        
        let cells = insights.limit(to: 1).map { DiffableCollectionItem<InsightView>(.init(insight: $0, mode: .carousel, action: insightCallback($0))) }
        
        return .init(Section.insights.rawValue, cells: cells, header: sectionHeader, sectionLayout: layout)
    }
    
    
    // MARK: - Refresh
    
    public func refresh() {
        refreshData.send(true)
    }
}
