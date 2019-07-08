//
//  OffersFlowLayout.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 06/06/2019.
//

import Foundation
class OffersViewFlowLayout: UICollectionViewFlowLayout {
    
    override var itemSize: CGSize {
        get {
            guard let cv = collectionView else { return .zero }
            return CGSize(width: cv.bounds.width, height: 108.0)
        }
        set {
            super.itemSize = newValue
        }
    }
    
    override var minimumInteritemSpacing: CGFloat {
        get {
            return 12.0
        }
        set {
            super.minimumInteritemSpacing = newValue
        }
    }
    
}
