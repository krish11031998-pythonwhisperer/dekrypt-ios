//
//  NewsViewController.swift
//  DekryptUI_Example
//
//  Created by Krishna Venkatramani on 14/01/2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import KKit
import Combine
import DekryptUI
import DekryptService

class NewsFeedViewController: TabViewController {

    private lazy var collectionView: UICollectionView = { .init(frame: .zero, collectionViewLayout: .init()) }()
    
    private let viewModel: NewsFeedViewControllerModel
    private var bag: Set<AnyCancellable> = .init()
    private lazy var refreshControl: UIRefreshControl = .init()
    private var reachedEndCancellable: AnyCancellable?
    
    init(newsService: NewsServiceInterface = NewsService.shared, includeSegmentControl: Bool = true, type: NewsFeedViewControllerModel.FeedType = .feed) {
        self.viewModel = .init(newsService: newsService, includeSegmentControl: includeSegmentControl, type: type)
        super.init(nibName: nil, bundle: nil)
    }
    
    override class var navName: String { "News" }
    
    override class var iconName: UIImage.Catalogue { .news }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.)
        setupView()
        bind()
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = .surfaceBackground
        collectionView.refreshControl = refreshControl
        startLoadingAnimation()
    }
    
    private func bind() {
        
        refreshControl
            .publisher(for: .valueChanged)
            .withUnretained(self)
            .sinkReceive { (vc, _) in
                vc.viewModel.refresh()
            }
            .store(in: &bag)
        
        let output = viewModel.transform()
        
        output.section
            .withUnretained(self)
            .sinkReceive({ (vc, section) in
                vc.endLoadingAnimation { [weak vc] in
                    vc?.collectionView.reloadWithDynamicSection(sections: section) {
                        vc?.afterReloading()
                    }
                }
            })
            .store(in: &bag)
        
        output.navigation
            .withUnretained(self)
            .sinkReceive { (vc, navigation) in
                switch navigation {
                case .toNews(let news):
                    vc.pushTo(target: NewsDetailView(news: news))
                }
            }
            .store(in: &bag)
    }
    
    private func afterReloading() {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        
        reachedEndCancellable?.cancel()
        reachedEndCancellable = collectionView.reachedEnd?
            .removeDuplicates()
            .filter({ $0 })
            .receive(on: DispatchQueue.main)
            .sink { state in
                print("(DEBUG) hasReached End: ", state)
                self.viewModel.nextPage.send(true)
            }
    }
}
