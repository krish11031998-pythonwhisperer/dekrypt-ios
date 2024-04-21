//
//  MainTabModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 13/02/2024.
//

import Foundation
import DekryptUI
import UIKit

struct MainTabModel: Equatable {
    let name: String
    let iconName: UIImage.Catalogue

    static func == (lhs: MainTabModel, rhs: MainTabModel) -> Bool {
        lhs.name == rhs.name
    }
    
    static let home: MainTabModel = .init(name: "Home", iconName: .home)
    static let tweets: MainTabModel = .init(name: "Tweets", iconName: .twitter)
    static let news: MainTabModel = .init(name: "News", iconName: .news)
    static let social: MainTabModel = .init(name: "News", iconName: .news)
    static let videos: MainTabModel = .init(name: "Video", iconName: .video)
    static let search: MainTabModel = .init(name: "Search", iconName: .searchOutline)
    static let profile: MainTabModel = .init(name: "Profile", iconName: .user)
}

extension MainTabModel {
    var tabImage: UIImage {
        let imgView = UIImageView(image: iconName.image)
        imgView.frame = .init(origin: .zero, size: .init(squared: 24))
        imgView.contentMode = .scaleAspectFit
        return imgView.snapshot
    }

    var tabBarItem: UITabBarItem {
        return .init(title: name, image: tabImage, selectedImage: tabImage)
    }
}

extension UIViewController {
    
    @discardableResult
    func tabBarItem(_ item: MainTabModel) -> Self {
        self.tabBarItem = item.tabBarItem
        return self
    }
}

