//
//  SplashScreenVIewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 11/09/2023.
//

import UIKit
import KKit
import DekryptUI

class SplashScreenViewController: UIViewController {
    
    private lazy var imageView: UIView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.setFrame(.init(squared: 150))
        imageView.image =  UIImage.Catalogue.logo.image
        imageView.clippedCornerRadius = 75
        return imageView
    }()
    private lazy var imageViewBackground: UIView = {
        UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    }()
    private lazy var loadingIndicator: LoadingIndicator = .init(showBackground: true, size: .init(squared: 32))
    private lazy var appNameHeader: UILabel = { .init() }()
    private lazy var appDetailHeader: UILabel = { .init() }()
    private var hasAnimated: Bool = false
    private let showIndicator: Bool
    
    init(showIndicator: Bool) {
        self.showIndicator = showIndicator
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init() {
        self.init(showIndicator: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateAppearance()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        loadingIndicator.stop()
    }
    
    private func setupView() {
        view.backgroundColor = .surfaceBackground
        
        [imageViewBackground, imageView]
            .forEach {
                view.addSubview($0)
                $0
                    .pinCenterXAnchorTo(constant: 0)
                    .pinCenterYAnchorTo(constant: 0)
            }
        
        view.addSubview(appNameHeader)
        appNameHeader
            .pinTopAnchorTo(imageView,
                            anchor: \.bottomAnchor,
                            constant: .appVerticalPadding * 2)
            .pinCenterXAnchorTo(constant: 0)
        
        view.addSubview(appDetailHeader)
        appDetailHeader
            .pinTopAnchorTo(appNameHeader,
                            anchor: \.bottomAnchor,
                            constant: .appVerticalPadding)
            .pinCenterXAnchorTo(constant: 0)
        
        
        view.addSubview(loadingIndicator)
        loadingIndicator
            .pinBottomAnchorTo(constant: .safeAreaInsets.bottom + .appVerticalPadding * 2)
            .pinCenterXAnchorTo(constant: 0)
        
        "Dekrypt".styled(font: CustomFonts.bold, color: .textColor, size: 32).render(target: appNameHeader)
        "One stop platform for all your cryptocurrency news"
            .body1Medium(color: .textColor)
            .render(target: appDetailHeader)
        
        imageViewBackground.alpha = 0
        loadingIndicator.alpha = 0
        appNameHeader.alpha = 0
        appDetailHeader.alpha = 0
        appNameHeader.transform = .init(translationX: 0, y: 10)
    }
    
    private func animateAppearance() {
        guard !hasAnimated else { return }
        let headerFrom = appNameHeader.frame.minY + 10
        let headerTo = appNameHeader.frame.minY
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.appNameHeader.transform = .identity
                self.appNameHeader.alpha = 1
                self.imageViewBackground.alpha = 1
                self.imageView.clippedCornerRadius = 75
                self.imageView.transform = .init(scaleX: 0.75, y: 0.75)
                self.imageViewBackground.alpha = 1
            } completion: {
                guard $0 else { return }
                self.hasAnimated = true
                if self.showIndicator {
                    UIView.animate(withDuration: 0.5, delay: 2, options: [.curveEaseInOut]) { [weak self] in
                        self?.loadingIndicator.start()
                    }
                }
            }
        }
        
    }
    
    deinit {
        print("(DEINIT) Splash Screen Deinit")
    }
}


@available(iOS 17.0, *)
#Preview {
    let splash = SplashScreenViewController()
    return splash.view
}
