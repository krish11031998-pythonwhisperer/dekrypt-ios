//
//  SubscriptionViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 01/06/2024.
//

import UIKit
import DekryptUI
import KKit
import RevenueCat

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
    
    private var monthlyProduct: SubscriptionPage.SubscriptionProduct {
        let monthlyProduct = RevenueCatManager.shared.monthlyProductToDisplay!
        return .init(localizedName: monthlyProduct.localizedTitle, localizedDescription: monthlyProduct.localizedDescription, localizedPrice: monthlyProduct.localizedPriceString)
    }
    
    private var yearlyProduct: SubscriptionPage.SubscriptionProduct? {
        guard let yearlyProduct = RevenueCatManager.shared.yearlyProductToDisplay else { return nil }
        return .init(localizedName: yearlyProduct.localizedTitle, localizedDescription: yearlyProduct.localizedDescription, localizedPrice: yearlyProduct.localizedPriceString)
    }
    
    private func setupView() {
        let subscriptionView = addSwiftUIView(SubscriptionPage(model: .init(monthlyProduct: monthlyProduct, yearlyProduct: yearlyProduct)))
        subscriptionView.fillSuperview()
        subscriptionView.overrideUserInterfaceStyle = .dark
    }
}
