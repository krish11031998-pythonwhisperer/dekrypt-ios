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

public class NewsFeedViewController: UIViewController {

    private lazy var collectionView: UICollectionView = { .init(frame: .zero, collectionViewLayout: .init()) }()
    
    private let viewModel: NewsFeedViewControllerModel
    private var bag: Set<AnyCancellable> = .init()
    
    
    public init(newsService: NewsServiceInterface = NewsService.shared, preloadedNews: [NewsModel] = []) {
        self.viewModel = .init(newsService: newsService, preloadedNews: preloadedNews)
        super.init(nibName: nil, bundle: nil)
    }
    
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
        setupNavBar()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    private func setupNavBar() {
        if navigationController?.viewControllers.first !== self {
            standardNavBar()
            showNavbar()
        } else {
            setupTransparentNavBar()
            standardNavBar(leftBarButton: .init(view: "News".styled(font: CustomFonts.semibold, color: .textColor, size: 24).generateLabel))
        }
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.section
            .receive(on: DispatchQueue.main)
            .sink { [weak self] section in
                self?.collectionView.reloadWithDynamicSection(sections: section) {
                    self?.afterReloading()
                }
            }
            .store(in: &bag)
        
        output.navigation
            .withUnretained(self)
            .sinkReceive { (vc, navigation) in
                switch navigation {
                case .toNews(let news):
                    vc.navigationController?.pushViewController(NewsDetailView(news: news), animated: true)
                    break
                }
            }
            .store(in: &bag)
    }
    
    private func afterReloading() {
        collectionView.reachedEnd?
            .removeDuplicates()
            .filter({ $0 })
            .receive(on: DispatchQueue.main)
            .sink { state in
                print("(DEBUG) hasReached End: ", state)
                self.viewModel.nextPage.send(true)
            }
            .store(in: &bag)
    }
}
