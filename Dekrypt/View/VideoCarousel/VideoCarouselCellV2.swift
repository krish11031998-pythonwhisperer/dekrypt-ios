//
//  VideoCarouselCellV2.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 15/04/2024.
//

import Foundation
import KKit
import UIKit
import DekryptUI
import DekryptService
import Combine

public class VideoPlayerViewV2: DiffableConfigurableCollectionCell {
    
    public struct Model: Hashable, ActionProvider {
        let video: VideoModel
        public var action: Callback?
        
        public init(video: VideoModel, action: Callback? = nil) {
            self.video = video
            self.action = action
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(video)
        }
        
        public static func == (lhs: Model, rhs: Model) -> Bool {
            lhs.video == rhs.video
        }
    }
    
    private lazy var player: YoutubePlayer = .init(playWhenReady: false , preloadVideo: true, withParams: true)
    private lazy var sourceLabel: UILabel = .init()
    private var bag: Set<AnyCancellable> = .init()
    private lazy var videoNameLabel: UILabel =  {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    private lazy var videoDescriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    private lazy var playButton: CustomButton = {
        let button = CustomButton()
        button.setImage(.init(systemName: "play.fill"), for: .normal)
        button.tintColor = .appBlack
        button.setFrame(.smallestSquare)
        button.backgroundColor = .appWhite
        button.clippedCornerRadius(radius: CGSize.smallestSquare.smallDim.half)
        return button
    }()
    
    private var isPlaying: Bool  = false
    @Published private var shouldPlay: Bool = false
    private var playerIsReady: Bool = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.backgroundColor = .appBlack
        
        contentView.addSubview(player)
        player.fillSuperview()
        
        let stack = UIStackView.VStack(subViews: [sourceLabel, videoNameLabel, videoDescriptionLabel], spacing: .appVerticalPadding, alignment: .leading, insetFromSafeArea: false)
        contentView.addSubview(stack)
        stack.addInsets(insets: .init(top: 0, left: .appHorizontalPadding, bottom: .safeAreaInsets.bottom, right: .appHorizontalPadding))
        stack
            .pinHorizontalAnchorsTo(constant: 0)
            .pinBottomAnchorTo(constant: 0)
        
        player.isUserInteractionEnabled = false
        contentView.addSubview(playButton)
        playButton.pinLeadingAnchorTo(constant: .appVerticalPadding)
            .pinBottomAnchorTo(stack, anchor: \.topAnchor, constant: .appVerticalPadding)
        
    }
    
    private func animatePlayButton(shouldPlay: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) { [weak self] in
            guard let self else { return }
            self.playButton.transform = !shouldPlay ? .identity : .init(translationX: 0, y: (self.frame.height - self.safeAreaInsets.bottom) - self.playButton.frame.maxY)
            self.playButton.setImage(shouldPlay ? .init(systemName: "pause.fill") : .init(systemName: "play.fill"), for: .normal)
            [videoNameLabel, videoDescriptionLabel, sourceLabel].forEach {
                $0.alpha = shouldPlay ? 0 : 1
            }
        }
    }
    
    private func bind() {
        playButton.tapPublisher
            .withLatestFrom(player.isPlayingPublisher)
            .map { (_, isPlaying) in isPlaying }
            .withUnretained(self)
            .sinkReceive { (view, isPlaying) in
                if isPlaying {
                    view.player.pauseVideo()
                } else {
                    view.player.playVideo()
                }
            }
            .store(in: &bag)
        
        player.isPlayingPublisher
            .withUnretained(self)
            .sinkReceive { (view, isPlaying) in
                view.isPlaying = isPlaying
                view.animatePlayButton(shouldPlay: isPlaying)
            }
            .store(in: &bag)
        
        player.durationProgressPublisher
            .withUnretained(self)
            .sinkReceive { (view, duration) in
                print("(DEBUG) duration: ", duration)
            }
            .store(in: &bag)
        
        player.isReadyToPlayPublisher.combineLatest($shouldPlay.setFailureType(to: Never.self).eraseToAnyPublisher())
            .withUnretained(self)
            .sinkReceive { (view, state) in
                let (_, shouldPlay) = state
                view.playerIsReady = true
                //view.player.animate(.fadeIn())
                if shouldPlay && !view.isPlaying {
                    view.player.playVideo()
                    if view.player.alpha == 0 {
                        view.player.animate(.fadeIn())
                    }
                } else if !shouldPlay && view.isPlaying{
                    view.player.pauseVideo()
                    view.player.alpha = 0
                }
            }
            .store(in: &bag)
        
        player.isBufferingPublisher.withLatestFrom(player.isPlayingPublisher)
//            .prefix(2)
            .withUnretained(self)
            .sinkReceive { (view, state) in
                let (buffering, isPlaying) = state
                if buffering && !isPlaying {
                    print("(DEBUG) isBuffering")
                    view.player.alpha = 0
                } else if !buffering && view.alpha == 0 {
                    view.player.animate(.fadeIn())
                }
            }
            .store(in: &bag)
        
    }
    
    public func configure(with model: Model) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
            self?.player.configure(with: model.video)
        }
        model.video.sourceName.styled(font: CustomFonts.regular, color: .gray, size: 10).render(target: sourceLabel)
        model.video.title.body1Medium(color: .appWhite).render(target: videoNameLabel)
        model.video.text.styled(font: CustomFonts.thin, color: .appWhite, size: 10).render(target: videoDescriptionLabel)
        DispatchQueue.main.async {
            self.player.alpha = 0
        }
    }
    
    public func playOrPauseVideo(play shouldPlay: Bool) {
        self.shouldPlay = shouldPlay
    }
    
}
