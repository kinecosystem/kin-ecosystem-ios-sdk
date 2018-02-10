//
//
//  Offer.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//

import Foundation

struct OffersList: Decodable {
    let offers: [Offer]
}

struct Offer: Decodable {
    let amount: Int
    let description: String
    let id: String
    let image: String
    let offer_type: String
    let title: String
}






