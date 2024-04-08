//
//  ProfileCell.swift
//  DekryptUI
//
//  Created by Krishna Venkatramani on 20/01/2024.
//

import Foundation
import KKit
import SwiftUI

public struct ProfileCell: ConfigurableView {
    
    public struct Model: ActionProvider, Hashable {
        let label: String
        let isLast: Bool
        public var action: Callback?
        
        public init(label: String, isLast: Bool = false, action: @escaping Callback) {
            self.label = label
            self.isLast = isLast
            self.action = action
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(label)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.label == rhs.label
        }
    }
    
    private let model: Model
    
    public init(model: Model) {
        self.model = model
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: .appVerticalPadding) {
            HStack(alignment: .firstTextBaseline, spacing: nil) {
                model.label.body2Medium()
                    .asText()
                Spacer()
            }
            
            if !model.isLast {
                Color.gray.opacity(0.24)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
            } else {
                Color.clear.frame(height: 0, alignment: .center)
            }
        }
        
    }
    
    public static func createContent(with model: Model) -> UIContentConfiguration {
        UIHostingConfiguration {
            ProfileCell(model: model)
        }
        .margins(.horizontal, .appHorizontalPadding)
        .margins(.bottom, .zero)//.standardColumnSpacing)
    }
    
    
    public static var viewName: String { "ProfileCell" }
}
