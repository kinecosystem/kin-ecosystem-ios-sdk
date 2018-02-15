//
//  CenterCellCollectionViewFlowLayout.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 14/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreDataStack

class CenterCellCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        guard let cv = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }
        
            let cvBounds = cv.bounds
            let halfWidth = cvBounds.size.width * 0.5;
            let proposedContentOffsetCenterX = proposedContentOffset.x + halfWidth;
        
        guard let attributesForVisibleCells = self.layoutAttributesForElements(in: cvBounds) else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }
        
        var candidateAttributes : UICollectionViewLayoutAttributes?
        for attributes in attributesForVisibleCells {
            
            if attributes.representedElementCategory != UICollectionElementCategory.cell {
                continue
            }
            
            if let candAttrs = candidateAttributes {
                
                let a = attributes.center.x - proposedContentOffsetCenterX
                let b = candAttrs.center.x - proposedContentOffsetCenterX
                
                if fabsf(Float(a)) < fabsf(Float(b)) {
                    candidateAttributes = attributes;
                }
                
            }
            else {
                candidateAttributes = attributes;
                continue;
            }
        }
        
        return CGPoint(x : candidateAttributes!.center.x - halfWidth, y : proposedContentOffset.y)
    }
    
    override var itemSize: CGSize {
        get {
            guard let cv = collectionView else { return .zero }
            let ratio = CGFloat(140)/CGFloat(166)
            let itemHeight = cv.bounds.height
            let itemWidth = floor(itemHeight * ratio)
            return CGSize(width: itemWidth, height: itemHeight)
        }
        set {
            super.itemSize = newValue
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init() {
        super.init()
        commonInit()
    }
    
    func commonInit() {
        sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        minimumInteritemSpacing = 0
        minimumLineSpacing = 20
        scrollDirection = .horizontal
    }
}
