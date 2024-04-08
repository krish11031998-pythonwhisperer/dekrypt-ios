//
//  MaintabViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 13/02/2024.
//

import Foundation
import DekryptUI
import UIKit
import DekryptService

class MainTabViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainApp()
    }
    
    private func setupMainApp() {
        view.backgroundColor = .clear
        let tabBar = { () -> MainTab in
            let tabBar = MainTab()
            tabBar.delegate = self
            self.selectedIndex = 0
            return tabBar
        }()
        self.setValue(tabBar, forKey: "tabBar")
        setViewControllers(tabBarViewController(), animated: true)
        selectedIndex = 0
        tabBar.tintColor = .surfaceBackgroundInverse
    }
    
    private func tabBarViewController(user: UserModel? = nil) -> [UINavigationController] {
        let homeViewController = HomeViewController().withNavigationController(swipable: true).tabBarItem(.home)
        let newsViewController = NewsFeedViewController().withNavigationController(swipable: true).tabBarItem(.news)
        let profileViewController = ProfileViewController().withNavigationController().tabBarItem(.profile)
        let searchViewController = SearchViewController().withNavigationController().tabBarItem(.search)
        
        return [homeViewController, searchViewController, newsViewController, profileViewController]
    }
    
}
