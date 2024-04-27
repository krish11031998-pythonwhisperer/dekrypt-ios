//
//  ProfileViewController.swift
//  DekryptUI
//
//  Created by Krishna Venkatramani on 20/01/2024.
//

import Foundation
import UIKit
import KKit
import Combine
import DekryptUI

public class ProfileViewController: UIViewController, TabViewController {
    
    private lazy var collectionView: UICollectionView = { .init(frame: .zero, collectionViewLayout: .init()) }()
    private let viewModel: ProfileViewModel = .init()
    private var bag: Set<AnyCancellable> = .init()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        hideNavbar()
        setupView()
        bind()
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.section
            .withUnretained(self)
            .sinkReceive{ (vc, section) in
                vc.collectionView.reloadWithDynamicSection(sections: section)
            }
            .store(in: &bag)
        
        output.navigation
            .withUnretained(self)
            .sinkReceive { (vc, nav) in
                switch nav {
                case .errorMessage(let err):
                    vc.presentErrorToast(error: err.localizedDescription)
                case .onboarding:
                    self.navigationController?.setViewControllers([OnboardingScreen()], animated: false)
                case .toTicker(let ticker):
                    vc.presentView(style: .sheet(), target: TickerDetailView(ticker: ticker, tickerName: ticker), onDimissal: nil)
                }
            }
            .store(in: &bag)
    }
    
    
    // MARK: - TabViewController
    
    var tabItem: MainTabModel { .profile }
}
