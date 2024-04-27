//
//  OnboardingScreen.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 30/09/2023.
//

import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit
import AuthenticationServices
import DekryptUI
import KKit

final class OnboardingScreen: UIViewController {
    fileprivate lazy var signInWithGoogleButton: CustomButton = { .init() }()
    fileprivate lazy var signInWithAppleButton: CustomButton = { .init() }()
    fileprivate lazy var buttonStack: UIStackView = { .VStack(subViews: [signInWithGoogleButton, signInWithAppleButton], spacing: 8) }()
    private var bag: Bag = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSplash()
        setupView()
        bind()
        hideNavbar()
    }
    
    private func addSplash() {
        let splash = SplashScreenViewController(showIndicator: false)
        addChild(splash)
        view.addSubview(splash.view)
        
        splash.view
            .pinTopAnchorTo(constant: 0)
            .pinLeadingAnchorTo(constant: 0)
            .pinTrailingAnchorTo(constant: 0)
            .pinBottomAnchorTo(anchor: \.centerYAnchor, constant: 0)
    }
    
    
    private func setupView() {
        view.backgroundColor = .surfaceBackground
        setupButtons()
    }
    
    private func setupButtons() {
        view.addSubview(buttonStack)
        buttonStack
            .pinLeadingAnchorTo(constant: .appHorizontalPadding)
            .pinTrailingAnchorTo(constant: .appHorizontalPadding)
            .pinBottomAnchorTo(constant: max(.safeAreaInsets.bottom, 10) + tabBarHeight)
  
        setupGoogleSignInButton()
        setupAppleSignInButton()
    }
    
    private func bind() {
        AppStorage.shared
            .userPublisher
            .compactMap { $0 }
            .sinkReceive { [weak self] _ in
                self?.navigationController?.setViewControllers([ProfileViewController()], animated: true)
            }
            .store(in: &bag)
    }
}

//MARK: - GoogleSignIn
extension OnboardingScreen {
    
    fileprivate func setupGoogleSignInButton() {
        let action: Callback = { [weak self] in
            guard let self else { return }
            print("(DEBUG) sign in with google")
            self.signInWithGoogle()
        }
        signInWithGoogleButton.configureButton(.signInButtonProviderConfig(
            buttonText: UIImage.Catalogue.googleLogo.image + (" Sign in with Google".body1Bold(color: .textColorInverse) as! NSAttributedString),
            backgroundColor: .surfaceBackgroundInverse,
            borderStyling: .signInGoogle,
            action: action))
    }
    
    fileprivate func signInWithGoogle() {
        FirebaseAuthService.shared.signInWithGoogle(self)
            .flatMap { FirebaseAuthService.shared.signInWithUserAuthCredentials(with: $0) }
            .justSink()
            .store(in: &bag)
    }
    
}

//MARK: - AppleSignIn
extension OnboardingScreen {
    
    fileprivate func setupAppleSignInButton() {
        let action: Callback = { [weak self] in self?.signInWithApple() }
        signInWithAppleButton.configureButton(.signInButtonProviderConfig(
            buttonText: UIImage.Catalogue.appleLogo.image.withTintColor(.textColorInverse) + (" Sign in with Apple".body1Bold(color: .textColorInverse) as! NSAttributedString),
            backgroundColor: .surfaceBackgroundInverse,
            borderStyling: .signInApple, action: action))
    }
    
    fileprivate func signInWithApple() {
        AppleAuthService.shared.signIn(view.window!)
    }
}
