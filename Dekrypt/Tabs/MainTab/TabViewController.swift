//
//  TabViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 15/05/2024.
//

import UIKit
import DekryptUI

class TabViewController: UIViewController, TabViewControllerType {
    
    var tabItem: MainTabModel { .init(name: Self.navName, iconName: Self.iconName) }
    
    class var showNavbar: Bool {
        true
    }
    
    class var navName: String {
        name
    }
    
    class var iconName: UIImage.Catalogue {
        .appleLogo
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Self.showNavbar {
            showNavbar()
        }
    }
    
    private func setupNavbar() {
        if navigationController?.viewControllers.first !== self {
            standardNavBar()
        } else {
            setupTransparentNavBar()
            standardNavBar(leftBarButton: .init(view: Self.navName.styled(font: CustomFonts.semibold, color: .textColor, size: 24).generateLabel))
            showNavbar()
        }
    }
    
    
}
