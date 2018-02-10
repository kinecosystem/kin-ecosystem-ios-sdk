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

enum OfferType: String {
    case earn
    case spend
}

struct OfferViewModel {
    
    let id: String
    let description: String
    let imageSource: String
    var image: Promise<ImageCacheResult> {
        get {
            return ImageCache.shared.image(for: URL(string: imageSource))
        }
    }
    let offerType: OfferType
    let title: String
    let amount: Int
    
    init(from model: Offer) {
        id = model.id
        description = model.description
        title = model.title
        imageSource = model.image
        offerType = OfferType(rawValue: model.offer_type)!
        amount = model.amount
    }
    
}
