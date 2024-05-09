//
//  VideoPlayerViewModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 09/05/2024.
//

import KKit
import DekryptUI
import DekryptService
import Combine
import UIKit

class VideoFeedViewModel {
    
    struct Input {
        let reachedEnd: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let sections: AnyPublisher<DiffableCollectionSection, Never>
        let videoToScrollTo: AnyPublisher<IndexPath, Never>?
    }
    
    private var videoModel: [VideoModel]
    private let videoToScrollTo: VideoModel?
    private var page: Int = 1
    private let videoService: VideoServiceInterface
    
    init(videoModel: [VideoModel], videoToScrollTo: VideoModel?, videoService: VideoServiceInterface) {
        self.videoModel = videoModel
        self.videoToScrollTo = videoToScrollTo
        self.videoService = videoService
    }
    
    func transform(input: Input) -> Output {
        
        let videos: AnyPublisher<[VideoModel], Never> = .just(videoModel)
        
        let fetchNextVideos = input.reachedEnd
            .withUnretained(self)
            .map { (vm, _) in vm.page }
            .removeDuplicates()
            .filter { page in page != -1 }
            .withUnretained(self)
            .flatMap { (vm, page) in
                print("(DEBUG) page: ", page)
                return vm.videoService.fetchVideo(entity: nil, page: page, limit: 10)
            }
            .replaceError(with: .init(data: nil, success: false, err: nil))
            .withUnretained(self)
            .compactMap { (vm, result) -> [VideoModel]? in
                guard let videos = result.data else {
                    vm.page = -1
                    return nil
                }
                vm.page += 1
                vm.videoModel += videos
                return vm.videoModel
            }
            .eraseToAnyPublisher()
        
        let videoToScrollTo: AnyPublisher<IndexPath, Never> = Just(videoToScrollTo)
            .compactMap { $0 }
            .withUnretained(self)
            .compactMap { (vm, videoToScrollTo) in
               let index = vm.videoModel.firstIndex { video in
                    video.title == videoToScrollTo.title
                }
                guard let index else { return nil }
                print("(DEBUG) vm.videoModel.firstIndex(of: video): ", index)
                return IndexPath(item: index, section: 0)
            }
            .eraseToAnyPublisher()
        
        let sections = Publishers.Merge(videos, fetchNextVideos)
            .map {
                let videoCells = $0.map { DiffableCollectionCell<VideoPlayerViewV2>(.init(video: $0)) }
                
                let sectionLayout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .fractionalHeight(1.0), insets: .section(.zero), spacing: 0)
                
                let section = DiffableCollectionSection(0, cells: videoCells, sectionLayout: sectionLayout)
                
                return section
            }
            .eraseToAnyPublisher()
        
        return .init(sections: sections, videoToScrollTo: videoToScrollTo)
    }
}
