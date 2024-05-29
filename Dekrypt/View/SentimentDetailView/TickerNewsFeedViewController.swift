//
//  TickerNewsFeedViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 28/05/2024.
//

import KKit
import UIKit
import DekryptUI
import DekryptService
import Combine

class TickerNewsFeedViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = { .init(frame: .zero, collectionViewLayout: .init()) }()
    private let viewModel: TickerNewsFeedViewModel
    private var bag: Set<AnyCancellable> = .init()
    
    init(ticker: String, date: String, newsService: NewsServiceInterface) {
        self.viewModel = .init(newsService: newsService, ticker: ticker, date: date)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        standardNavBar()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavbar()
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.backgroundColor = .surfaceBackground
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.sections
            .withUnretained(self)
            .sinkReceive { (vc, section) in
                vc.collectionView.reloadWithDynamicSection(sections: section)
            }
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
}
