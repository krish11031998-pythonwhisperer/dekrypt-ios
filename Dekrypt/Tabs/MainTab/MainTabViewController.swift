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
    private var watchlist: WatchlistViewController!
    
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
        watchlist = WatchlistViewController()
        #else
        home = HomeViewController(socialService: SocialHighlightService.shared, videoService: VideoService.shared)
        news = NewsFeedViewController(newsService: NewsService.shared)
        profile = ProfileViewController()
        search = SearchViewController()
        watchlist = WatchlistViewController()
        #endif
        return [home, search, news, watchlist].map { ($0 as! TabViewControllerType).asTabController() }
    }
    
    private func setupInitialLoadListeners() {
        Publishers.Zip3(home.initialLoad, search.initialLoad, AppStorage.shared.userPublisher.prefix(1))
            .map { (_, _, _) in  () }
            .withUnretained(self)
            .sinkReceive { (vc, _) in
                print("(DEBUG) initial Things loaded Up!")
                vc.initialLoad.send(())
            }
            .store(in: &bag)
    }
    
}
