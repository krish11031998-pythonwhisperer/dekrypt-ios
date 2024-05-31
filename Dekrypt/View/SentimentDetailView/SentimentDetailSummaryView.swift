//
//  SentimentDetailHeaderView.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 28/05/2024.
//

import KKit
import DekryptUI
import DekryptService
import Combine
import SwiftUI

extension SentimentForTicker: Hashable {
    public static func == (lhs: SentimentForTicker, rhs: SentimentForTicker) -> Bool {
        lhs.total == rhs.total && lhs.timeline == rhs.timeline
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(timeline)
        hasher.combine(total)
    }
}

struct SentimentDetailSummaryView: ConfigurableView {
   
    enum ChartType: FilterType {
        case timeline, breakdown
        
        var name: String {
            switch self {
            case .timeline:
                return "Timeline"
            case .breakdown:
                return "Breakdown"
            }
        }
        
        static var allCases: [SentimentDetailSummaryView.ChartType] {
            [.timeline, .breakdown]
        }
    }
    
    typealias Model = SentimentForTicker
    @State var type: ChartType = .timeline
    private let sentimentModel: SentimentForTicker

    private func breakdownView(total: SentimentModel) -> some View {
        VStack(alignment: .center, spacing: .appVerticalPadding) {
            VStack(alignment: .leading, spacing: 4){
                "Sentiment Breakdown"
                    .body1Bold()
                    .asText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                "Last 30 days"
                    .bodySmallMedium(color: .systemGray)
                    .asText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            SentimentBreakdownView(model: .init(sentiment: total, lineWidth: 7.5))
        }
        .padding(.vertical, .appVerticalPadding)
        .padding(.horizontal, .appHorizontalPadding)
        .frame(maxWidth: .infinity, alignment: .center)
        .asCard(cornerRadius: 16, material: .regular)
        .padding(.trailing, CGFloat.appHorizontalPadding)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: .appVerticalPadding) {
            GeometryReader { proxy in
                LazyHStack(alignment: .center, spacing: .appHorizontalPadding) {
                    if let sentiments = sentimentModel.timeline {
                        SentimentChartView(sentiment: Array(sentiments.values.dropFirst(sentiments.count - 30)))
                            .frame(width: proxy.size.width, alignment: .center)
                    }
                    if let total = sentimentModel.total {
                        breakdownView(total: total)
                            .frame(width: proxy.size.width, alignment: .center)                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .offset(x: self.type == .breakdown ? -proxy.size.width : 0)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            FilterView<ChartType> {
                self.type = $0
            }
        }
        .animation(.easeInOut, value: type)
    }
    
    static func createContent(with model: Model) -> any UIContentConfiguration {
        UIHostingConfiguration {
            SentimentDetailSummaryView(sentimentModel: model)
        }
        .margins(.vertical, .zero)
        .margins(.horizontal, .zero)
    }
    
    static var viewName: String { "SentimentDetailHeaderView" }
}


