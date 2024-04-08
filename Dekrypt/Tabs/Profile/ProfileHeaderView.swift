//
//  ProfileHeaderView.swift
//  DekryptUI
//
//  Created by Krishna Venkatramani on 21/01/2024.
//

import KKit
import SwiftUI
import Combine
import DekryptUI

public struct ProfileHeaderView: ConfigurableView {
    
    public struct Model: Hashable {
        let profileImageView: ImageSource
        let profileName: String
        let profileUsername: String
        
        public init(profileImageView: ImageSource, profileName: String, profileUsername: String) {
            self.profileImageView = profileImageView
            self.profileName = profileName
            self.profileUsername = profileUsername
        }
    }
    
    private let model: Model
    
    init(model: Model) {
        self.model = model
    }

    public var body: some View {
        HStack(alignment: .top, spacing: .appHorizontalPadding.half) {
            ImageView(src: model.profileImageView, contentMode: .fill)
                .frame(width: 72, height: 72, alignment: .center)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: .standardColumnSpacing) {
                model.profileName
                    .body1Bold()
                    .asText()
                
                model.profileUsername
                    .bodySmallMedium(color: .gray)
                    .asText()
            }
            .padding(.top, .appVerticalPadding.half.half)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    public static func createContent(with model: Model) -> UIContentConfiguration {
        UIHostingConfiguration {
            ProfileHeaderView(model: model)
        }.margins(.horizontal, .appHorizontalPadding)
    }
    
    public static var viewName: String { "ProfileHeaderView" }
}

