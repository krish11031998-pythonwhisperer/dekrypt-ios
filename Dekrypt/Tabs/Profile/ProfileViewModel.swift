//
//  ProfileViewModel.swift
//  DekryptUI
//
//  Created by Krishna Venkatramani on 20/01/2024.
//

import Foundation
import Combine
import KKit
import DekryptUI
import UIKit

public class ProfileViewModel {
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
    }
    
    enum ProfileSettings: String, Hashable, CaseIterable {
        case profile, reportBug, habit
        
        
        var stylizedText: String {
            switch self {
            case .profile:
                return "🧑‍🚀  Profile"
            case .reportBug:
                return "👻  Report Bug"
            case .habit:
                return "⌚️  Set Habit Time"
            }
        }
    }
    
    enum Section: Int, Hashable, CaseIterable {
        case profile = 0, tickers, general
        
        var name: String {
            switch self {
            case .profile:
                return "Profile"
            case .general:
                return "General"
            case .tickers:
                return "Tickers"
            }
        }
    }
    
    func transform() -> Output {
        
        let sections = Section.allCases.map { section in
            switch section {
            case .profile:
                return profileSection()
            case .tickers:
                return tickerSection()
            case .general:
                return generalSection()
            }
        }
        
        return .init(section: Just(sections).setFailureType(to: Never.self).eraseToAnyPublisher())
    }
    
    
    // MARK: - Setup User Section
    
    private func generalSection() -> DiffableCollectionSection {
        let cells = ProfileSettings.allCases
            .map { setting in
                return DiffableCollectionItem<ProfileCell>(.init(label: setting.stylizedText, isLast: ProfileSettings.allCases.last == setting, action: {
                    print("(DEBUG) setting: ", setting.rawValue)
                }))
            }
        
        let sectionLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1), height: .estimated(44), insets: .section(.init(vertical: .appVerticalPadding, horizontal: 0)), spacing: .standardColumnSpacing)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44)))
        
        let header = CollectionSupplementaryView<SectionHeader>(.init(label: Section.general.name))
        
        let buttonModel: DekryptButton.Model = .init(text: "Sign Out".buttonBold(color: .appRed)) {
            print("(DEBUG) Sign Out")
        }
        
        let signOutButton = DiffableCollectionItem<DekryptButton>(buttonModel)
        
        let section = DiffableCollectionSection(Section.general.rawValue, cells: cells + [signOutButton], header: header, sectionLayout: sectionLayout)
        
        return section
    }
    
    private func tickerSection() -> DiffableCollectionSection {
        let tickers: [String] = ["BTC", "ETH", "XRP", "USDT", "AVAX", "DOT", "MATIC", "LTC"]
        
        let cell = DiffableCollectionItem<TickerGrid>(.init(tickers: tickers, action: { ticker in
            print("(DEBUG) clicked on this ticker: ", ticker)
        }))
        
        let height = TickerGrid.height(tickers: tickers, width: .totalWidth - (2 * .appHorizontalPadding)) + (2 * .standardColumnSpacing)
        
        let sectionLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1), height: .absolute(height), insets: .section(.init(vertical: .standardColumnSpacing, horizontal: 0)), spacing: .standardColumnSpacing)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44)))
        
        let header = CollectionSupplementaryView<SectionHeader>(.init(label: Section.tickers.name))
        
        let section = DiffableCollectionSection(Section.tickers.rawValue, cells: [cell], header: header, sectionLayout: sectionLayout)
        
        return section
    }
     
    
    private func profileSection() -> DiffableCollectionSection {
        
        let profileImageURL: String = "https://signal.up.railway.app/user/profileImage?path=crybsePostImage/jV217MeUYnSMyznDQMBgoNHfMvH2_profileImage.jpg"
        
        let imageSource = ImageSource.remote(url: profileImageURL)
        
        let cell = DiffableCollectionItem<ProfileHeaderView>(.init(profileImageView: imageSource, profileName: "Krishna Venkatramani", profileUsername: "@krishUser"))
        
        let layout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(150), insets: .section(.init(vertical: .standardColumnSpacing, horizontal: 0)))
        
        return .init(Section.profile.rawValue, cells: [cell], sectionLayout: layout)
        
    }
}
