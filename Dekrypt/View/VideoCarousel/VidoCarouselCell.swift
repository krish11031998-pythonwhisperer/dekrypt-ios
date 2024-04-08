//
//  VidoCarouselCell.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 04/04/2024.
//

import KKit
import UIKit
import Combine
import DekryptService
import DekryptUI

class VideoCarouselCell: DiffableConfigurableCollectionCell {
    
    private lazy var videoPlayer: YoutubePlayer = .init(playWhenReady: true, preloadVideo: true)
    private lazy var stackView: UIStackView = .VStack(subViews: [videoPlayer, videoInfo], spacing: .appVerticalPadding * 0.75, insetFromSafeArea: true)
    private lazy var videoInfo: DualLabel = .init(spacing: .appVerticalPadding.half, axis: .vertical, addSpacer: .trailing, alignment: .leading)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.addSubview(stackView)
        stackView.fillSuperview()
        contentView.clippedCornerRadius = .extraCornerRadius
        contentView.backgroundColor = .appRed
        videoPlayer.setHeight(height: .totalHeight * 0.7)
        videoPlayer.clipsToBounds = true
        videoInfo.insets(.init(vertical: 0, horizontal: .appHorizontalPadding))
        videoInfo.setNumberOfLines(forTitle: 1, forSubtitle: 3)
    }
    
    func configure(with model: VideoModel) {
        videoPlayer.configure(with: model)
        videoInfo.configure(title: model.sourceName.capitalized.body2Medium(color: .gray),
                            subtitle: model.title.body1Semibold())
        videoPlayer.clippedCornerRadius = .extraCornerRadius
    }
    
    
    static var cellName: String { name }
}

