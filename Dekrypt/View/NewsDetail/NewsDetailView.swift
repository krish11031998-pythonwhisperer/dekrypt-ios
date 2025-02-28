//
//  NewsDetailView.swift
//  DekryptUI
//
//  Created by Krishna Venkatramani on 29/01/2024.
//

import Foundation
import UIKit
import Combine
import KKit
import DekryptUI
import DekryptService
import SwiftUI

public class SentimentTextLabel: UILabel {
    public func configureIndicator(label: String, color: UIColor, showIndicator: Bool = false) {
        var result: NSAttributedString
        if showIndicator {
            result = "Sentiment:    ".body3Medium() as! NSAttributedString
            let sentiment = UIImage.solid(color: color, circleFrame: .init(squared: 10)) + (label.bodySmallRegular() as! NSAttributedString)
            result = result.appending(sentiment)
        } else {
            result = UIImage.solid(color: color, circleFrame: .init(squared: 10)) + (label.bodySmallRegular() as! NSAttributedString)
        }
        result.render(target: self)
        //indicator.backgroundColor = color
    }
    
}

public class NewsDetailView: UIViewController {
    
    static var visitCount: Int = 0
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    private lazy var titleLabel: UILabel = { .init() }()
    private lazy var authorLabel: UILabel = { .init() }()
    private lazy var descriptionLabel: UILabel = { .init() }()
    private lazy var viewNews: UIView = { .init() }()
    private lazy var scrollView: DekryptUI.ScrollView = { .init(spacing: 24,
                                                      ignoreSafeArea: true,
                                                                inset: .init(vertical: .appVerticalPadding, horizontal: .appHorizontalPadding),
                                                      axis: .vertical) }()
    private lazy var topicsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var backButton: CustomButton = {
        let image: UIImage.Catalogue = .chevronLeft
        let button = CustomButton()
        button.configureButton(.navBarButton(image.image))
        return button
    }()
    
    private lazy var shareButton: UIButton = {
        let image: UIImage = .Catalogue.share.image.resized(size: .init(squared: 16)).withTintColor(.surfaceBackgroundInverse)
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.setFrame(.smallestSquare)
        return button
    }()
    
    private lazy var shareButtonBlurView: UIView = {
        let blurView = UIVisualEffectView.init(effect: UIBlurEffect(style: .systemMaterial))
        let view = UIView()
        view.addSubview(blurView)
        blurView.fillSuperview()
        
        view.addSubview(shareButton)
        shareButton.fillSuperview()
        view.cornerRadius = CGSize.smallestSquare.smallDim.half
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var sentimentView: SentimentTextLabel = .init()
    
    private var imageHeight: NSLayoutConstraint!
    private lazy var shadowView: UIView = { .init() }()
    private var imageViewGradient: CALayer?
    
    private var bag: Set<AnyCancellable> = .init()
    
    private lazy var viewMoreButton: UIButton = {
        let button = CustomButton()
        button.configureButton(.primaryCTA("View News"))
        return button
    }()
//    private var tickers: TickerSymbolsStackView = { .init() }()
    private let news: NewsModel
    
    init(news: NewsModel) {
        self.news = news
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupObservers()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideTabBarIfRequired()
        hideNavbar()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showTabBarIfRequired()
    }
  
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addGradient()
        addGradientToImage()
        #if DEBUG
        scrollView.contentSize.height = 2 * .totalHeight
        #endif
    }
    
    private func setupView() {
        view.backgroundColor = .surfaceBackground
     
        view.addSubview(backButton)
        view.setFittingConstraints(childView: backButton, top: .safeAreaInsets.top, leading: .appHorizontalPadding, width: 32, height: 32)
        titleLabel.numberOfLines = 0
        descriptionLabel.numberOfLines = 0
        
        news.title.heading2().render(target: titleLabel)
        news.text.body2Medium().render(target: descriptionLabel)
        news.sourceName.body2Medium(color: .gray).render(target: authorLabel)
        imageView.loadImage(from: news.imageUrl)
        setupMainStack()
        setupTopics()
    }
    
    private func setupNav() {
        if modalPresentationStyle == .custom {
            standardNavBar(rightBarButton: Self.closeButton(self),
                           color: .clear, scrollColor: .clear)
            navigationItem.leftBarButtonItem = nil
        } else {
            standardNavBar(color: .clear, scrollColor: .clear)
        }
    }
    
    private func hideTabBarIfRequired() {
        guard navigationController?.modalPresentationStyle != .custom else { return }
        navigationController?.tabBarController?.tabBar.hide = true
    }
    
    private func showTabBarIfRequired() {
        guard navigationController?.modalPresentationStyle != .custom else { return }
        navigationController?.tabBarController?.tabBar.hide = false
    }
    
    private func setupMainStack() {
//        tickers.isHidden = true
        
        scrollView.showsVerticalScrollIndicator = false
        view.insertSubview(scrollView, at: 0)
        view.setFittingConstraints(childView: scrollView, insets: .zero)
        
        view.insertSubview(imageView, belowSubview: scrollView)
        imageView
            .pinHorizontalAnchorsTo(constant: 0)
            .pinTopAnchorTo(constant: 0)
        
        imageHeight = imageView.setHeight(height: .totalHeight * 0.4, priority: .required)
        
        //ImageView
        let imageTransparentView = UIView()
        imageTransparentView.backgroundColor = .clear
        imageTransparentView.addSubview(shareButtonBlurView)
        shareButtonBlurView
            .pinTrailingAnchorTo(constant: .zero)
            .pinBottomAnchorTo(constant: .appVerticalPadding * 2)
        scrollView.addArrangedView(view: imageTransparentView)
        imageTransparentView.setHeight(height: .totalHeight * 0.4)
        
        scrollView.setCustomSpacing(view: imageTransparentView, spacing: 0)
        
        //Article Introduction
        let articleIntro = setupArticleIntro()
        sentimentView.configureIndicator(label: news.sentiment.rawValue, color: news.sentiment.color, showIndicator: true)
        
        articleIntro.addSubview(sentimentView)
        sentimentView.pinTrailingAnchorTo(constant: 0)
            .pinBottomAnchorTo(constant: 0)
        scrollView.addArrangedView(view: articleIntro)
        
        //Tickers
        setupTickers()
        
        // Description
        scrollView.addArrangedView(view: descriptionLabel)
        
        scrollView.contentInset.bottom = .safeAreaInsets.bottom + Constants.buttonHeight + .appVerticalPadding
        
        view.addSubview(viewMoreButton)
        view.setFittingConstraints(childView: viewMoreButton,
                                   leading: .appHorizontalPadding,
                                   trailing: .appHorizontalPadding,
                                   bottom: .safeAreaInsets.bottom.boundTo(lower: 10, higher: .totalHeight))
        
        view.insertSubview(shadowView, belowSubview: viewMoreButton)
        view.setFittingConstraints(childView: shadowView,
                                   leading: 0,
                                   trailing: 0,
                                   bottom: 0)
        shadowView.topAnchor.constraint(equalTo: viewMoreButton.topAnchor,
                                        constant: -.appVerticalPadding).isActive = true
        
    }
    
    private func setupTopics() {
        var resultedString: NSAttributedString = .init(string: "")
        guard let topics = news.topics else { return }
        topics.enumerated().forEach {
            let idx = $0.offset
            guard let topic = ($0.element.capitalized + "   ").body3Medium(color: .gray) as? NSAttributedString else { return }
            
            if idx == 0 {
                resultedString = topic
            } else {
                let result = UIImage.solid(color: .gray, circleFrame: .init(squared: 4)) + topic
                resultedString = resultedString.appending(result)
            }
        }
        resultedString.render(target: topicsLabel)
    }
    
    private func setupArticleIntro() -> UIView {
        let stack = [topicsLabel, titleLabel, authorLabel].embedInVStack(alignment: .leading, spacing: 8)
        return stack
    }
    
    private func setupTickers() {
        if let tickers = news.tickers, !tickers.isEmpty {
            let model = TickerGrid.Model(tickers: tickers) { [weak self] ticker in
                self?.pushTo(target: TickerDetailView(ticker: ticker, tickerName: ticker))
            }
            let tickerGrid = TickerGrid(model: model)
            let hostingVC = UIHostingController(rootView: tickerGrid)
            addChild(hostingVC)
            hostingVC.didMove(toParent: self)
            
            hostingVC.view.setHeight(height: TickerGrid.height(tickers: tickers, width: .totalWidth - 2 * .appHorizontalPadding))
            scrollView.addArrangedView(view: hostingVC.view)
        }
    }
    
    private func setupObservers() {
        viewMoreButton.publisher(for: .touchUpInside)
            .sink(receiveValue: showWebpage(_:))
            .store(in: &bag)
        
        backButton.tapPublisher
            .withUnretained(self)
            .sinkReceive { (vc, _) in
                vc.popViewController()
            }
            .store(in: &bag)
        
        shareButton
            .tapPublisher
            .withUnretained(self)
            .sinkReceive { (vc, _) in
                guard let newsURL = URL(string: vc.news.newsUrl) else { return }
                let activity = UIActivityViewController(activityItems: [newsURL],
                                                        applicationActivities: nil)
                vc.present(activity, animated: true)
            }
            .store(in: &bag)
        
        let scrollViewOff = scrollView.publisher(for: \.contentOffset)
            .map(\.y)
            .share()
        
        scrollViewOff
            .filter { $0 <= 0 }
            .withUnretained(self)
            .sinkReceive { (vc, off) in
                vc.imageHeight.constant = Constants.imageHeight - off
            }
            .store(in: &bag)
        
        scrollViewOff
            .filter { $0 > 0 && $0 < Constants.imageHeight }
            .withUnretained(self)
            .sinkReceive { (vc, off) in
                let percent = (0...Constants.imageHeight).percent(off)
                vc.imageViewGradient?.opacity = Float(percent).rounded(.down)
                vc.imageView.alpha = 1 - percent
            }
            .store(in: &bag)
        
//        tickers
//            .tickerSelected
//            .withUnretained(self)
//            .sinkReceive { (strongSelf, ticker) in
//                strongSelf.pushTo(target: TickerDetailView(ticker: ticker, tickerName: ticker) )
//            }
//            .store(in: &bag)
        
        NewsArticleParser.shared.fetchArticle(urlString: news.newsUrl)
            .withUnretained(self)
            .sinkReceive { (vc, elements) in
                for element in elements {
                    switch element {
                    case .text(let str):
                        print("(DEBUG) text: ", str)
                    case .image(let url):
                        print("(DEBUG) img: ", url.absoluteString)
                    }
                }
            }
            .store(in: &bag)
    }
    
    private func addGradient() {
        guard shadowView.layer.sublayers == nil else { return }
        let color: UIColor = .surfaceBackground
        let gradient = shadowView.gradient(color: [color.withAlphaComponent(0.1), color.withAlphaComponent(0.5), color],
                                           type: .axial,
                                           direction: .down)
        shadowView.layer.addSublayer(gradient)
    }
    
    private func addGradientToImage() {
        guard imageView.layer.sublayers == nil else { return }
        let color: UIColor = .surfaceBackground
        let gradient = imageView.gradient(color: [.clear, color, color, color],
                                          direction: .down)
        gradient.opacity = 0
        imageViewGradient = gradient
        imageView.layer.addSublayer(gradient)
    }
    
    private func showWebpage(_ publisher: UIControl.EventPublisher.Output) {
        let webPage = WebPageView(url: news.newsUrl, title: news.title).withNavigationController()
        presentView(style: .sheet(), target: webPage) {
            if Self.visitCount < Constants.countToShowAd {
                Self.visitCount += 1
            } else {
                //self.loadAd()
                Self.visitCount = 0
            }
            
        }
    }
}


extension NewsDetailView {
    enum Constants {
        static let countToShowAd = 5
        static let imageHeight: CGFloat = .totalHeight * 0.4
        static let buttonHeight: CGFloat = CustomButtonType.default.height
    }
}
