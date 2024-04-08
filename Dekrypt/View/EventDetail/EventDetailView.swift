//
//  EventDetailView.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 13/02/2024.
//

import Foundation
import KKit
import DekryptUI
import Combine
import DekryptService
import UIKit

class EventDetailView: UIViewController {
    
    private lazy var collectionView: UICollectionView = { .init(frame: .zero, collectionViewLayout: .init()) }()
    private let viewModel: EventDetailViewModel
    private var bag: Set<AnyCancellable> = .init()
    
    init(event: EventModel) {
        self.viewModel = .init(eventModel: event)
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
        collectionView.showsVerticalScrollIndicator = false
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.section
            .withUnretained(self)
            .sinkReceive { (vc, sections) in
                vc.collectionView.reloadWithDynamicSection(sections: sections)
            }
            .store(in: &bag)
        
        output.navigation
            .withUnretained(self)
            .sinkReceive { (vc, nav) in
                switch nav {
                case .selectedNews(let news):
                    vc.pushTo(target: NewsDetailView(news: news))
                case .toTickerDetail(let ticker):
                    vc.pushTo(target: TickerDetailView(tickerService: TickerService.shared,
                                                       eventService: EventService.shared,
                                                       ticker: ticker,
                                                       tickerName: ticker))
                default:
                    break
                }
            }
            .store(in: &bag)
    }
    
}
