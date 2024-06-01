//
//  SubscriptionViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 01/06/2024.
//

import UIKit
import DekryptUI
import KKit

class SubscriptionViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        standardNavBar(color: .clear, scrollColor: .clear)
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavbar()
    }
    
    private func setupView() {
        let subscriptionView = addSwiftUIView(SubscriptionPage())
        subscriptionView.fillSuperview()
        subscriptionView.overrideUserInterfaceStyle = .dark
    }
    
}
