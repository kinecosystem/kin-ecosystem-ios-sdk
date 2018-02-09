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

struct OffersListViewModel: Decodable {
    var offers: [OfferViewModel]
}

struct OfferViewModel: Decodable {
    
    fileprivate(set) var description: String
    fileprivate var imageSource: String
    var image: Promise<ImageCacheResult> {
        get {
            return ImageCache.shared.image(for: imageSource)
        }
    }
    fileprivate(set) var offerType: OfferType
    fileprivate(set) var title: String
    fileprivate(set) var amount: Int
    
    enum OfferViewModelKeys: String, CodingKey {
        case description
        case title
        case image
        case offer_type
        case amount
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: OfferViewModelKeys.self)
        description = try values.decode(String.self, forKey: .description)
        title = try values.decode(String.self, forKey: .title)
        imageSource = try values.decode(String.self, forKey: .image)
        let offerTypeDecoded = try values.decode(String.self, forKey: .offer_type)
        offerType = OfferType(rawValue: offerTypeDecoded)!
        amount = try values.decode(Int.self, forKey: .amount)
    }
    
}
