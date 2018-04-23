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

@available(iOS 9.0, *)
struct OfferViewModel {
    
    let id: String
    let subtitle: NSAttributedString
    fileprivate var imageSource: String
    var image: Promise<ImageCacheResult> {
        get {
            return ImageCache.shared.image(for: URL(string:imageSource))
        }
    }
    let title: NSAttributedString
    let amount: NSAttributedString
    
    init(with model: Offer) {
        id = model.id
        imageSource = model.image
        title = model.title.attributed(16.0, weight: .regular, color: .kinBlueGrey)
        subtitle = model.description_.attributed(14.0, weight: .regular, color: .kinBlueGreyTwo)
        amount = ((model.offerType == .earn ? "+" : "") + "\(Decimal(model.amount).currencyString()) Kin").attributed(14.0, weight: .medium, color: .kinDeepSkyBlue)
    }
    
}
