//
//  SentimentPageControl.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 08/04/2024.
//

import KKit
import UIKit
import DekryptUI
import DekryptService
import Combine

class SentimentPageControl: UICollectionReusableView, ConfigurableCollectionSupplementaryView {
    
    private lazy var pageControl = UIPageControl()
    private var sentimentPage: AnyPublisher<Int, Never>! {
        didSet { bind() }
    }
    private var cancellable: AnyCancellable?
    
    struct Model: Hashable {
        let count: Int
        let startIndex: Int
        let updateIndex: AnyPublisher<Int, Never>
        
        init(count: Int, startIndex: Int, updateIndex: AnyPublisher<Int, Never>) {
            self.count = count
            self.startIndex = startIndex
            self.updateIndex = updateIndex
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(count)
            hasher.combine(startIndex)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.count == rhs.count && lhs.startIndex == rhs.startIndex
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(pageControl)
        pageControl
            .pinCenterXAnchorTo(constant: 0)
            .pinTopAnchorTo(constant: 0)
            .pinBottomAnchorTo(constant: .standardColumnSectionSpacing)
        
        pageControl.direction = .leftToRight
        pageControl.currentPageIndicatorTintColor = .appBlue
        pageControl.pageIndicatorTintColor = .greyscale400
    }
    
    private func bind() {
        cancellable?.cancel()
        cancellable = sentimentPage
            .withUnretained(self)
            .sinkReceive { (control, index) in
                control.pageControl.currentPage = index
            }
    }
    
    func configure(with model: Model) {
        pageControl.numberOfPages = model.count
        pageControl.currentPage = model.startIndex
        sentimentPage = model.updateIndex
    }
    
    deinit {
        cancellable?.cancel()
    }
}
