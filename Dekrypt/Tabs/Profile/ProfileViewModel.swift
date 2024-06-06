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
import DekryptService
import UIKit

public class ProfileViewModel {
    
    private let navigationPublisher: PassthroughSubject<Navigation, Never> = .init()
    
    enum Navigation {
        case onboarding
        case toTicker(String)
        case errorMessage(Error)
        case toSubscription
        case toProfile
    }
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
        let navigation: AnyPublisher<Navigation, Never>
    }
    
    enum ProfileSettings: String, Hashable, CaseIterable {
        case profile, reportBug, subscription//, habit
        
        
        var stylizedText: String {
            switch self {
            case .profile:
                return "🧑‍🚀  Profile"
            case .reportBug:
                return "👻  Report Bug"
            case .subscription:
                return "🧾 Manage Subcription"
//            case .habit:
//                return "⌚️  Set Habit Time"
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
    
    private var hasFetchedProducts: Bool {
        RemoteConfigManager.shared.includeSubscriptionManagementValue && RevenueCatManager.shared.monthlyProductToDisplay != nil
    }
    
    func transform() -> Output {
        #if DEBUG
        let sections = Section.allCases.map { section in
            switch section {
            case .profile:
                return Self.profileSection()
            case .tickers:
                return Self.tickerSection()
            case .general:
                return Self.generalSection()
            }
        }

        return .init(section: Just(sections).setFailureType(to: Never.self).eraseToAnyPublisher(),
                     navigation: navigationPublisher.eraseToAnyPublisher())
        #else
        let sections = AppStorage.shared.userPublisher
            .compactMap({ $0 })
            .withUnretained(self)
            .map { (vm, user) in
                return [vm.profileSection(user: user), vm.generalSection()].compactMap({ $0 })
            }
            .eraseToAnyPublisher()
        
        
        // Navigation
        
        let showOnboardingIfNeccessary = AppStorage.shared.userPublisher
            .filter { $0 == nil }
            .map { _ in Navigation.onboarding }
            .eraseToAnyPublisher()
        
        let navigation = Publishers.Merge(navigationPublisher.eraseToAnyPublisher(), showOnboardingIfNeccessary)
            .eraseToAnyPublisher()
        
        return .init(section: sections, navigation: navigation)
        #endif
    }
    
    private func generalSection() -> DiffableCollectionSection {
        
        let sectionAction: (ProfileSettings) -> Callback = { [weak self] setting in
            {
                self?.navigateTo(setting: setting)
            }
        }
        
        let profileSettings = {
            if hasFetchedProducts {
                return ProfileSettings.allCases
            } else {
                return  ProfileSettings.allCases.filter( { $0 != .subscription })
            }
        }()
        
        let cells = profileSettings
            .map { setting in
                return DiffableCollectionItem<ProfileCell>(.init(label: setting.stylizedText, isLast: profileSettings.last == setting, action: sectionAction(setting)))
            }
        
        let sectionLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1), height: .estimated(44), insets: .section(.init(vertical: .appVerticalPadding, horizontal: 0)), spacing: .standardColumnSpacing)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44)))
        
        let header = CollectionSupplementaryView<SectionHeader>(.init(label: Section.general.name))
        
        let buttonModel: DekryptButton.Model = .init(text: "Sign Out".buttonBold(color: .appRed)) {
            print("(DEBUG) Sign Out")
            FirebaseAuthService.shared.signOutUser()
        }
        
        let signOutButton = DiffableCollectionItem<DekryptButton>(buttonModel)
        
        let section = DiffableCollectionSection(Section.general.rawValue, cells: cells + [signOutButton], header: header, sectionLayout: sectionLayout)
        
        return section
    }
    
    private func tickerSection(user: UserModel) -> DiffableCollectionSection? {
        guard let tickers: [String] = user.watching, !tickers.isEmpty else { return nil }
        
        let cell = DiffableCollectionItem<TickerGrid>(.init(tickers: tickers, action: { [weak self] ticker in
            print("(DEBUG) clicked on this ticker: ", ticker)
            self?.navigationPublisher.send(.toTicker(ticker))
        }))
        
        let height = TickerGrid.height(tickers: tickers, width: .totalWidth - (2 * .appHorizontalPadding)) + (2 * .standardColumnSpacing)
        
        let sectionLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1), height: .absolute(height), insets: .section(.init(vertical: .standardColumnSpacing, horizontal: 0)), spacing: .standardColumnSpacing)
            .addHeader(size: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44)))
        
        let header = CollectionSupplementaryView<SectionHeader>(.init(label: Section.tickers.name))
        
        let section = DiffableCollectionSection(Section.tickers.rawValue, cells: [cell], header: header, sectionLayout: sectionLayout)
        
        return section
    }
     
    
    private func profileSection(user: UserModel) -> DiffableCollectionSection {
        
        let profileImageURL: String = user.img
        
        let imageSource = ImageSource.remote(url: profileImageURL)
        
        let cell = DiffableCollectionItem<UserHeaderView>(.init(profileImageView: imageSource, profileName: user.name, profileUsername: user.uid, watchlist: user.watching ?? [], isPro: user.isPro, showPro: false))
        
        let layout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(150), insets: .sectionInsets)
        
        return .init(Section.profile.rawValue, cells: [cell], sectionLayout: layout)
    }
    
    private func navigateTo(setting: ProfileSettings) {
        switch setting {
        case .profile:
            navigationPublisher.send(.toProfile)
        case .reportBug:
            break
        case .subscription:
            return navigationPublisher.send(.toSubscription)
        }
    }
}

#if DEBUG
extension ProfileViewModel {
    // MARK: - Setup User Section
    
    fileprivate static func generalSection() -> DiffableCollectionSection {
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
    
    fileprivate static  func tickerSection() -> DiffableCollectionSection {
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
     
    
    fileprivate static  func profileSection() -> DiffableCollectionSection {
        
        let profileImageURL: String = "https://signal.up.railway.app/user/profileImage?path=crybsePostImage/jV217MeUYnSMyznDQMBgoNHfMvH2_profileImage.jpg"
        
        let imageSource = ImageSource.remote(url: profileImageURL)
        
        let cell = DiffableCollectionItem<UserHeaderView>(.init(profileImageView: imageSource, profileName: "Krishna Venkatramani", profileUsername: "@krishUser", watchlist: ["BTC"], isPro: true, showPro: true))
        
        let layout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(150), insets: .section(.init(vertical: .standardColumnSpacing, horizontal: 0)))
        
        return .init(Section.profile.rawValue, cells: [cell], sectionLayout: layout)
        
    }

}
#endif
