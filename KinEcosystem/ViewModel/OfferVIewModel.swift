//
//
//  OfferVIewModel.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//


import Foundation
import UIKit

struct OfferViewModel {
    
    fileprivate(set) var id: String
    fileprivate(set) var description: String
    fileprivate var imageSource: String
    var image: Promise<ImageCacheResult> {
        get {
            return ImageCache.shared.image(for: URL(string:imageSource))
        }
    }
    fileprivate(set) var offerType: OfferType
    fileprivate(set) var title: String
    fileprivate(set) var amount: Int32
    
    init(with model: Offer) {
        description = model.description_
        imageSource = model.image
        offerType = model.offerType
        title = model.title
        amount = model.amount
        id = model.id
    }
    
}
