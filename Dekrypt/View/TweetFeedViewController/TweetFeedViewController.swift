//
//  TweetFeedViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 09/06/2024.
//

import UIKit
import DekryptService
import DekryptUI
import Combine

public class TweetFeedViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = { .init(frame: .zero, collectionViewLayout: .init()) }()
    private let viewModel: TweetFeedViewModel
    private var bag: Set<AnyCancellable> = .init()
    
    public init(tweetService: TweetServiceInterface = TweetService.shared, ticker: String, tickerName: String) {
        self.viewModel = .init(tweetService: tweetService, tickerName: tickerName, ticker: ticker)
        super.init(nibName: nil, bundle: nil )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        standardNavBar()
        bind()
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
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
    }
}
