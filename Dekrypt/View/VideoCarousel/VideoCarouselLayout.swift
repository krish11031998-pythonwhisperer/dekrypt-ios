//
//  VideoCarouselLayout.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 04/04/2024.
//

import UIKit
import Combine

class VideoCarouselCellAttribute: UICollectionViewLayoutAttributes {
    var playVideo: Bool = false
}

class VideoCarouselLayout: UICollectionViewLayout {
    
    private var cache: [VideoCarouselCellAttribute] = []
    private var contentHeight: CGFloat = .zero
    
    var itemHeight: CGFloat = .totalHeight * 0.8
    
    var items: Int {
        collectionView?.numberOfItems(inSection: 0) ?? 0
    }
    
    var contentOffsetY: CGFloat {
        collectionView?.contentOffset.y ?? .zero
    }
    
    override var collectionViewContentSize: CGSize {
        .init(width: .totalWidth, height: contentHeight)
    }
    
    override func prepare() {
        var maxY: CGFloat = 0
        for idx in 0..<items {
            let attribute = VideoCarouselCellAttribute(forCellWith: .init(item: idx, section: 0))
            attribute.frame = .init(origin: .init(x: .zero, y: maxY), size: .init(width: .totalWidth, height: itemHeight))
            cache.append(attribute)
            maxY = max(attribute.frame.height, maxY)
        }
        contentHeight = maxY
    }
    
    override class var layoutAttributesClass: AnyClass { VideoCarouselCellAttribute.self }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cache.compactMap { attribute in
            guard attribute.frame.intersects(rect) else { return nil }
            if attribute.frame.minY == contentOffsetY {
                // Play Video
                attribute.playVideo = true
            } else {
                attribute.playVideo = false
            }
            return attribute
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }
}
