//
//  InsightViewModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 09/04/2024.
//

import DekryptService
import Combine
import DekryptUI
import KKit
import UIKit

class InsightViewModel {
    
    private let insightsService: SocialHighlightServiceInterface
    private let errorMessage: PassthroughSubject<String?, Error> = .init()
    private var shareConnectable: AnyCancellable?
    private let currentPageIndex: PassthroughSubject<Int, Never> = .init()
    private let navigation: PassthroughSubject<Navigation, Never> = .init()
    public var verticalInsets: CGFloat = 0
    
    enum Section: Int {
        case insight = 1
        
        var name: String {
            switch self {
            case .insight:
                return "Insights"
            }
        }
    }
    
    enum Navigation {
        case toInsight(InsightDigestModel)
    }
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
        let count: AnyPublisher<Int, Never>
        let currentPage: AnyPublisher<Int, Never>
        let navigation: AnyPublisher<Navigation, Never>
    }
    
    init(insightService: SocialHighlightServiceInterface) {
        self.insightsService = insightService
    }
    
    func transform() -> Output {
        
        let insights = insightsService.fetchInsightDigest(page: 1, limit: 10)
            .delay(for: 1.0, scheduler: DispatchQueue.global(qos: .background))
            .replaceError(with: .init(data: nil, success: false, err: nil))
            .compactMap(\.data)
            .eraseToAnyPublisher()
            .share()
        
        let sections = insights
            .withUnretained(self)
            .map { (vm, insights) -> [DiffableCollectionSection] in
                return [vm.setupInsight(insight: insights)]
            }
            .eraseToAnyPublisher()
        
        let pageControlCount = insights
            .map { $0.count }
            .replaceError(with: 0)
            .eraseToAnyPublisher()
        
        
        return .init(section: sections, count: pageControlCount, currentPage: currentPageIndex.eraseToAnyPublisher(), navigation: navigation.eraseToAnyPublisher())
    }
    
    private func setupInsight(insight: [InsightDigestModel]) -> DiffableCollectionSection {
        
        let layout = NSCollectionLayoutSection.singleRowLayout(width: .fractionalWidth(1.0), height: .absolute(.totalHeight - verticalInsets), insets: .sectionInsets, spacing: .appHorizontalPadding)
        layout.orthogonalScrollingBehavior = .groupPagingCentered
        
        layout.visibleItemsInvalidationHandler = NSCollectionLayoutSection.zoomInOutScrollAnimation(minScale: 0.9) { [weak self] items, offset, environment in
            guard let self else { return }
            let frame = environment.container.contentSize
            let index = (offset.x/frame.width).rounded(.down)
            self.currentPageIndex.send(Int(index))
        }
        
        let action: (InsightDigestModel) -> Callback = { [weak self] insight in
            {
                self?.navigation.send(.toInsight(insight))
            }
        }
        
        let cells = insight.map { DiffableCollectionItem<InsightView>(.init(insight: $0, mode: .reader, horizontalInset: .appHorizontalPadding, action: action($0)))
        }
        
        return .init(Section.insight.rawValue, cells: cells, sectionLayout: layout)
    }
    
    deinit { shareConnectable?.cancel() }
}
