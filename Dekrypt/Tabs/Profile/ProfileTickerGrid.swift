//
//  ProfileTickerView.swift
//  DekryptUI
//
//  Created by Krishna Venkatramani on 20/01/2024.
//

import Foundation
import KKit
import SwiftUI
import DekryptUI

// MARK: - TickerLayoutAttribute

fileprivate struct TickerLayoutAttribute: LayoutValueKey {
    
    static var defaultValue: CGSize = .zero
    
    typealias Value = CGSize
}


// MARK: - TickerLayout

fileprivate struct TickerLayout: Layout {
    
    private let tickers: [String]
    
    init(tickers: [String]) {
        self.tickers = tickers
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let width = proposal.width, let height = proposal.height else { return .zero }
        return .init(width: width, height: height)
    }
    
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var maxX = bounds.minX
        var maxY = max(0, bounds.minY)
        
        let totalWidth = proposal.width ?? .totalWidth
        subviews.indices.forEach { idx in
            
            let view = subviews[idx]
            
            let size = view[TickerLayoutAttribute.self]
            
            if maxX + size.width > (bounds.minX + totalWidth) {
                maxX = bounds.minX
                maxY += size.height + 8
            }
            
            view.place(at: .init(x: maxX, y: maxY), proposal: .init(size))
            
            let widthFactor = size.width + 8
            
            if maxX + widthFactor < (bounds.minX + totalWidth) {
                maxX += widthFactor
            } else {
                maxX = bounds.minX
                maxY += size.height + 8
            }
        }
    }
}


// MARK: - TickerView

public struct ProfileTickerGrid: ConfigurableView {
    
    public struct Model: Hashable {
        let tickers: [String]
        let action: ((String) -> Void)?
        
        public init(tickers: [String], action: ((String) -> Void)?) {
            self.tickers = tickers
            self.action = action
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(tickers)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.tickers.count == rhs.tickers.count else { return false }
            return zip(lhs.tickers, rhs.tickers).reduce(true, { $0 && ($1.0 == $1.1) })
        }
    }
    
    private let model: Model
    
    public init(model: Model) {
        self.model = model
    }
    
    public var body: some View {
        TickerLayout(tickers: model.tickers) {
            ForEach(model.tickers, id: \.self) { ticker in
                viewBuilder(ticker: ticker)
            }
        }
    }
    
    private func viewBuilder(ticker: String) -> some View {
        return TickerSentimentView(model: .init(ticker: ticker, type: .plain))
            .layoutValue(key: TickerLayoutAttribute.self, value: TickerSentimentView.sizeOfView(ticker: ticker))
            .asTickerButton {
                model.action?(ticker)
            }
    }
    
    public static func createContent(with model: Model) -> UIContentConfiguration {
        UIHostingConfiguration {
            ProfileTickerGrid(model: model)
        }.margins(.horizontal, .appHorizontalPadding)
    }
    
    public static var viewName: String { "TickerGridView" }
    
    public static func height(tickers: [String], width totalWidth: CGFloat) -> CGFloat {
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        
        tickers.forEach { ticker in
            let size = TickerSentimentView.sizeOfView(ticker: ticker)
            
            let widthFactor = size.width + 8
            let heightFactor = size.height + 8
            
            if maxX + size.width > totalWidth {
                maxX = widthFactor
                maxY += heightFactor
            } else {
                if maxX + widthFactor < totalWidth {
                    maxX += widthFactor
                } else {
                    maxX = widthFactor
                    maxY += heightFactor
                }
            }
            
            if tickers.last == ticker {
                maxY += size.height
            }
        }
        
        return maxY
    }
}
