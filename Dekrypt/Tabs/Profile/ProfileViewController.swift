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
        checkIfUserIsLoggedIn()
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    }
    
    private func checkIfUserIsLoggedIn(animate: Bool = true) {
        if AppStorage.shared.user == nil {
            //self.navigationController?.setViewControllers([OnboardingController(desiredHomeVC: ProfileViewController())], animated: animate)
            self.navigationController?.setViewControllers([OnboardingScreen()], animated: animate)
        }
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.section
            .receive(on: DispatchQueue.main)
            .sink { [weak self] section in
                self?.collectionView.reloadWithDynamicSection(sections: section)
            }
            .store(in: &bag)
    }
    
    
    // MARK: - TabViewController
    
    var tabItem: MainTabModel { .profile }
}
