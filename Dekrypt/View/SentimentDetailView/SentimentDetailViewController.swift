//
//  SentimentDetailViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 29/05/2024.
//

import KKit
import UIKit
import DekryptUI
import DekryptService
import Combine

class SentimentDetailViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = { .init(frame: .zero, collectionViewLayout: .init()) }()
    private let viewModel: SentimentDetailViewModel
    private let ticker: String
    private var bag: Set<AnyCancellable> = .init()
    
    init(model: SentimentForTicker, ticker: String) {
        self.ticker = ticker
        self.viewModel = .init(sentimentForTicker: model)
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
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .surfaceBackground
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.section
            .withUnretained(self)
            .sinkReceive { (vc, section) in
                vc.collectionView.reloadWithDynamicSection(sections: section)
            }
            .store(in: &bag)
        
        output.navigation
            .withUnretained(self)
            .sinkReceive { (vc, nav) in
                switch nav {
                case .toNewsDate(let model, let date):
                    vc.pushTo(target: TickerNewsFeedViewController(ticker: vc.ticker, date: date, newsService: NewsService.shared))
                }
            }
            .store(in: &bag)
    }
    
}
