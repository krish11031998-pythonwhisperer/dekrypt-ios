//
//  UserInfoViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 01/06/2024.
//

import KKit
import DekryptUI
import DekryptService
import UIKit
import Combine

class UserInfoViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = { .init(frame: .init(), collectionViewLayout: .init()) }()
    private var bag: Set<AnyCancellable> = .init()
    private let viewModel: UserInfoViewModel = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        standardNavBar(color: .clear, scrollColor: .clear)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavbar()
        bind()
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
        
        output.userDelete
            .withUnretained(self)
            .sinkReceive { (vc, _) in
                vc.dismiss(animated: true)
            }
            .store(in: &bag)
    }
}
