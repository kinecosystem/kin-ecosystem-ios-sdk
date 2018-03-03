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
import KinUtil

struct OfferViewModel {
    
    let id: String
    let description: String
    fileprivate var imageSource: String
    var image: Promise<ImageCacheResult> {
        get {
            return ImageCache.shared.image(for: URL(string:imageSource))
        }
    }
    let offerType: OfferType
    let contentType: OfferContentType
    let title: String // TODO attributed base on balance
    let amount: Int32
    
    init(with model: Offer) {
        description = model.description_
        imageSource = model.image
        offerType = model.offerType
        contentType = model.offerContentType
        title = model.title
        amount = model.amount
        id = model.id
    }
    
}
