//
//
//  OffersList.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//


import Foundation

class OffersList: Codable {
    
    var offers: [Offer]
    
    enum OffersKey: String, CodingKey {
        case offers
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: OffersKey.self)
        try container.encode(offers, forKey: .offers)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OffersKey.self)
        offers = try container.decode([Offer].self, forKey: .offers)
    }
    
}
