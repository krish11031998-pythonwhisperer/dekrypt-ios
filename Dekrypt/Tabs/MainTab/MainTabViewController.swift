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
import Combine

class MainTabViewController: UITabBarController {
    
    private(set) var initialLoad: PassthroughSubject<Void, Never> = .init()
    private var bag: Set<AnyCancellable> = .init()
    private var home: HomeViewController!
    private var news: NewsFeedViewController!
    private var profile: ProfileViewController!
    private var search: SearchViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainApp()
        home.loadViewIfNeeded()
        search.loadViewIfNeeded()
        setupInitialLoadListeners()
    }
    
    private func setupMainApp() {
        view.backgroundColor = .clear
//        let tabBar = { () -> MainTab in
//            let tabBar = MainTab()
//            tabBar.delegate = self
//            self.selectedIndex = 0
//            return tabBar
//        }()
//        self.setValue(tabBar, forKey: "tabBar")
        setViewControllers(tabBarViewController(), animated: true)
        selectedIndex = 0
        tabBar.tintColor = .surfaceBackgroundInverse
    }
    
    private func tabBarViewController(user: UserModel? = nil) -> [UINavigationController] {
        #if DEBUG
        home = HomeViewController()
        news = NewsFeedViewController()
        profile = ProfileViewController()
        search = SearchViewController()
        
        #else
        home = HomeViewController(socialService: SocialHighlightService.shared, videoService: VideoService.shared)
        news = NewsFeedViewController(newsService: NewsService.shared)
        profile = ProfileViewController()
        search = SearchViewController(searchService: TickerService.shared)
        #endif
        return [home, search, news, profile].map { ($0 as! TabViewController).asTabController() }
    }
    
    private func setupInitialLoadListeners() {
        home.initialLoad.combineLatest(search.initialLoad)
            .map { (_, _) in  () }
            .withUnretained(self)
            .sinkReceive { (vc, _) in
                print("(DEBUG) initial Things loaded Up!")
                vc.initialLoad.send(())
            }
            .store(in: &bag)
    }
    
}
