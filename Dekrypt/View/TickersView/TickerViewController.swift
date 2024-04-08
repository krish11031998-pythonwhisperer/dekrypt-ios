//
//  TickerViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 13/02/2024.
//

import Foundation
import KKit
import DekryptUI
import Combine
import UIKit
import DekryptService

class TickerViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = { .init(frame: .init(), collectionViewLayout: .init()) }()
    private let viewModel: TickerViewModel
    private var bag: Set<AnyCancellable> = .init()
    
    public init(model: TickerViewModel) {
        self.viewModel = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bind()
        standardNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavbar()
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.section
            .withUnretained(self)
            .sinkReceive { (vc, section) in
                vc.collectionView.reloadWithDynamicSection(sections: section)
            }
            .store(in: &bag)
        
        output.selectedNavigation
            .withUnretained(self)
            .sinkReceive { (vc, navigation) in
                switch navigation {
                case .toTicker(let ticker, let name):
                    let tickerDetail = TickerDetailView(tickerService: TickerService.shared, eventService: EventService.shared, ticker: ticker, tickerName: name)
                    vc.navigationController?.pushViewController(tickerDetail, animated: true)
                }
            }
            .store(in: &bag)
    }
    
    
    
}
