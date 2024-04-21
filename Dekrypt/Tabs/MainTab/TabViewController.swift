//
//  TabViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 21/04/2024.
//

import Foundation
import UIKit

protocol TabViewController {
    var tabItem: MainTabModel { get }
    func asTabController() -> UINavigationController
}

extension TabViewController where Self: UIViewController {
    func asTabController() -> UINavigationController {
        self.withNavigationController(swipable: true).tabBarItem(tabItem)
    }
}
