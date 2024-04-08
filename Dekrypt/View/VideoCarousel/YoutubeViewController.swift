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
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, VideoModel>!
    private let videoModels: [VideoModel]
    let cellRegistration = {
        UICollectionView.CellRegistration<VideoCarouselCell, VideoModel> { cell, indexPath, model in
            cell.configure(with: model)
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
        standardNavBar(color: .clear, scrollColor: .clear, showBackByDefault: true)
        // setupDataSource()
        // apply(videoModels)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview(inset: .zero)
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
}
//
//// MARK: - DiffableDataSource
//
//extension YoutubeViewController {
//    
//    private func setupDataSource() {
//        let cellRegistration = UICollectionView.CellRegistration<VideoCarouselCell, VideoModel> { cell, indexPath, model in
//            cell.configure(with: model)
//        }
//        
//        dataSource = UICollectionViewDiffableDataSource<Int, VideoModel>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
//            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
//        }
//    }
//    
//    private func apply(_ videos: [VideoModel]) {
//        var snapshot = NSDiffableDataSourceSnapshot<Int, VideoModel>()
//        snapshot.appendSections([0])
//        
//        snapshot.appendItems(videos, toSection: 0)
//        
//        dataSource.apply(snapshot, animatingDifferences: true)
//    }
//    
//}
