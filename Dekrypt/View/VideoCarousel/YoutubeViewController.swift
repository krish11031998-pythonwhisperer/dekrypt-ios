//
//  YoutubeViewController.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 03/04/2024.
//

import UIKit
import Combine
import KKit
import DekryptUI
import DekryptService
import YouTubeiOSPlayerHelper
import WebKit


class YoutubeViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView =  {
        let collection : UICollectionView = .init(frame: .zero, collectionViewLayout: VideoCarouselLayout())
        collection.isPagingEnabled = true
        collection.contentInsetAdjustmentBehavior = .never
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, VideoModel>!
    private let videoModels: [VideoModel]
    let cellRegistration = {
        UICollectionView.CellRegistration<VideoPlayerViewV2, VideoModel> { cell, indexPath, model in
            cell.configure(with: .init(video: model))
        }
    }()
    
    init(videoModel: [VideoModel]) {
        self.videoModels = videoModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        standardNavBar(title: "Video".styled(font: CustomFonts.semibold, color: .appWhite, size: 24),
                       leftBarButton: Self.closeButton(self),
                       color: .clear,
                       scrollColor: .clear,
                       showBackByDefault: true)
        // loadCollection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview(inset: .zero)
    }
    
    private func loadCollection() {
        let cells = videoModels.map {
            DiffableCollectionCell<VideoPlayerViewV2>(.init(video: $0))
        }
        
        let sectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1), height: .fractionalHeight(1))
        
        sectionLayout.visibleItemsInvalidationHandler =  { cells, offset, _ in
            cells.forEach { cell in
                guard let videoCell = cell as? VideoPlayerViewV2 else { return }
                if cell.frame.minY - offset.y == 0 {
                    videoCell.playOrPauseVideo(play: true)
                } else {
                    videoCell.playOrPauseVideo(play: false)
                }
            }
        }
        
        collectionView.reloadWithDynamicSection(sections: [.init(0, cells: cells, sectionLayout: sectionLayout)])
    }
    
}

// MARK: - DataSource

extension YoutubeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        videoModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: videoModels[indexPath.item])
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        collectionView.visibleCells.forEach { cell in
            guard let videoCell = cell as? VideoPlayerViewV2 else { return }
            if cell.frame.minY - scrollView.contentOffset.y == 0 {
                print("(DEBUG) PLAY \(cell)")
                videoCell.playOrPauseVideo(play: true)
            } else {
                print("(DEBUG) PAUSE \(cell)")
                videoCell.playOrPauseVideo(play: false)
            }
            
        }
    }
}
