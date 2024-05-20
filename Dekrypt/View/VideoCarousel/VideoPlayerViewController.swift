//
//  YoutubeViewControllerV2.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 09/05/2024.
//

import UIKit
import Combine
import KKit
import DekryptUI
import DekryptService
import YouTubeiOSPlayerHelper

class VideoFeedViewController: UIViewController {

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
        collectionView.isPagingEnabled = true
        collectionView.contentInsetAdjustmentBehavior = .never
        return collectionView
    }()
    private var bag: Set<AnyCancellable> = .init()
    private let viewModel: VideoFeedViewModel
    private let reachedEnd: PassthroughSubject<Void, Never> = .init()
    private var autoScrollToVideoIfNeeded: Bool
    
    init(videoModel: [VideoModel], videoToScrollTo: VideoModel? = nil, videoService: VideoServiceInterface = VideoService.shared) {
        self.viewModel = .init(videoModel: videoModel, videoToScrollTo: videoToScrollTo, videoService: videoService)
        self.autoScrollToVideoIfNeeded = videoToScrollTo != nil
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        standardNavBar(title: "Video".styled(font: CustomFonts.semibold, color: .appWhite, size: 24),
                       leftBarButton: isPresented ? Self.closeButton(self) : nil,
                       color: .clear,
                       scrollColor: .clear,
                       showBackByDefault: true)
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isPresented {
            hideTabBar()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !isPresented {
            showTabBar()
        }
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        collectionView.fillSuperview()
    }
    
    private func bind() {
        
        let output = viewModel.transform(input: .init(reachedEnd: reachedEnd.eraseToAnyPublisher()))
        
        output.sections
            .withUnretained(self)
            .sinkReceive { (vc, section) in
                vc.collectionView.reloadWithDynamicSection(sections: [section]) { [weak vc] in
                    vc?.setupReachedEnd(videoToScrollTo: output.videoToScrollTo)
                }
            }
            .store(in: &bag)
        
        collectionView.publisher(for: \.contentOffset)
            .withUnretained(self)
            .sinkReceive { (vc, offset) in
                vc.collectionView.visibleCells.forEach { cell in
                    guard let videoPlayer = cell as? VideoPlayerViewV2 else { return }
                    if cell.frame.minY - offset.y == 0 {
                        videoPlayer.playOrPauseVideo(play: true)
                    } else {
                        videoPlayer.playOrPauseVideo(play: false)
                    }
                }
            }
            .store(in: &bag)
        
    }
    
    private func setupReachedEnd(videoToScrollTo: AnyPublisher<IndexPath, Never>?) {
        guard autoScrollToVideoIfNeeded else { return }
        autoScrollToVideoIfNeeded = false
        videoToScrollTo?
            .withUnretained(self)
            .sinkReceive({ (vc, index) in
                vc.collectionView.scrollToItem(at: index, at: .top, animated: false)
            })
            .store(in: &bag)
        
        guard let reachedEnd = collectionView.reachedEnd else { return }
        
        reachedEnd
            .removeDuplicates()
            .filter { $0 }
            .withUnretained(self)
            .sinkReceive { (vc, _) in
                print("(DEBUG) reachedEnd!")
                vc.reachedEnd.send(())
            }
            .store(in: &bag)
        
        
    }
}

