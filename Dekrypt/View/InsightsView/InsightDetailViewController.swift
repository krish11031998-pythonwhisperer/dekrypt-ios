//
//  InsightDetailViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 24/05/2024.
//

import UIKit
import KKit
import DekryptService
import DekryptUI
import SwiftUI

class InsightDetailViewController: UIViewController {
    
    private let insight: InsightDigestModel
    
    init(insight: InsightDigestModel) {
        self.insight = insight
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        standardNavBar()
        showNavbar()
    }
    
    private func setupView() {
        let hostingView = UIHostingController(rootView: InsightView(model: .init(insight: insight, mode: .largeReader, horizontalInset: .zero, action: nil)))
        addChild(hostingView)
        view.addSubview(hostingView.view)
        hostingView.view.fillSuperview()
        view.backgroundColor = .surfaceBackgroundInverse
    }
    
}
