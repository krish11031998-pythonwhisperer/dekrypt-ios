//
//  InsightsViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 09/04/2024.
//

import KKit
import UIKit
import DekryptService
import DekryptUI
import Combine

class InsightViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
    private weak var collectionBottomConstraint: NSLayoutConstraint!
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .appBlue
        pageControl.pageIndicatorTintColor = .systemGray
        return pageControl
    }()
    
    private let viewModel: InsightViewModel = .init(insightService: SocialHighlightService.shared)
    private var bag: Set<AnyCancellable> = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavbar()
        hideTabBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showTabBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.contentInset.bottom = .safeAreaInsets.bottom + 2 * .appVerticalPadding + pageControl.frame.height
    }
    
    private func setupView() {
        view.backgroundColor = .surfaceBackground
        view.addSubview(collectionView)
        collectionView.backgroundColor = .surfaceBackground
        collectionView
            .pinHorizontalAnchorsTo(constant: 0)
            .pinTopAnchorTo(constant: 0)
        
        collectionView.clipsToBounds = true
        
        collectionBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        collectionBottomConstraint.isActive = true
        
        view.addSubview(pageControl)
        pageControl
            .pinHorizontalAnchorsTo(constant: .appHorizontalPadding * 2)
            .pinBottomAnchorTo(constant: .appVerticalPadding)
        pageControl.isUserInteractionEnabled = false
        viewModel.verticalInsets = .safeAreaInsets.bottom + 2 * .appVerticalPadding + pageControl.compressedSize.height + .safeAreaInsets.top + navBarHeight
        standardNavBar()
    }
    
    private func bind() {
        let output = viewModel.transform()
        
        output.section
            .withUnretained(self)
            .sinkReceive { (vc, sections) in
                vc.collectionView.reloadWithDynamicSection(sections: sections)
            }
            .store(in: &bag)
        
        output.count
            .withUnretained(self)
            .sinkReceive { (vc, count) in
                vc.pageControl.numberOfPages = count
            }
            .store(in: &bag)
        
        output.currentPage
            .removeDuplicates()
            .withUnretained(self)
            .sinkReceive { (vc, index) in
                vc.pageControl.currentPage = index
            }
            .store(in: &bag)
        
        output.navigation
            .withUnretained(self)
            .sinkReceive { (vc, nav) in
                switch nav {
                case .toInsight(let digest):
                    vc.pushTo(target: InsightDetailViewController(insight: digest))
                }
            }
            .store(in: &bag)
    }
}
