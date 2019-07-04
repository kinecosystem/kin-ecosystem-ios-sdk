//
//  OffersCollectionViewFlowLayout.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 14/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreDataStack

class OffersCollectionViewFlowLayout: UICollectionViewFlowLayout {
   
    @IBInspectable
    var itemWHRatio: CGFloat = 1.0
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        guard let collectionView = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        let maxOffset = collectionViewContentSize.width - collectionView.bounds.width
        var lastOffset = CGFloat(0)
        var availableOffsets = [CGFloat(0), CGFloat(maxOffset)]
        
        for i in 0..<collectionView.numberOfItems(inSection: 0) {
            if i == 0 {
                let offset = sectionInset.left + itemSize.width
                lastOffset = offset
                availableOffsets.append(offset)
            } else {
                let offset = lastOffset + minimumLineSpacing + itemSize.width
                lastOffset = offset
                if offset < maxOffset {
                    availableOffsets.append(offset)
                }
            }
        }
        
        guard availableOffsets.count > 1 else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }
        
        availableOffsets.sort()
        
        var closestValidOffset = availableOffsets.reduce(maxOffset) { (offset, availableOffset) -> CGFloat in
            if  abs(proposedContentOffset.x - availableOffset) < abs(proposedContentOffset.x - offset) {
                return availableOffset
            }
            return offset
        }
        
        let index = availableOffsets.index(of: closestValidOffset)!
        if collectionView.contentOffset.x > closestValidOffset, velocity.x > 0, index + 1 < availableOffsets.count {
            closestValidOffset = availableOffsets[index + 1]
        } else if collectionView.contentOffset.x < closestValidOffset, velocity.x < 0, index - 1 >= 0 {
            closestValidOffset = availableOffsets[index - 1]
        }
        
        return CGPoint(x: closestValidOffset, y:0)
    }
    
    override var itemSize: CGSize {
        get {
            guard let cv = collectionView else { return .zero }
            let ratio = itemWHRatio
            let itemHeight = cv.bounds.height
            let itemWidth = floor(itemHeight * ratio)
            return CGSize(width: itemWidth, height: itemHeight)
        }
        set {
            super.itemSize = newValue
        }
    }
}
