//
//  SpendViewModel.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 26/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import KinUtil
import KinCoreSDK

@available(iOS 9.0, *)
class SpendViewModel: Decodable {
    
    var title: NSAttributedString
    var description: NSAttributedString
    fileprivate var imageSource: String
    var confirmation: SpendViewModel?
    var buttonLabel: NSAttributedString?
    var amount: Int32?
    var image: Promise<ImageCacheResult> {
        get {
            return ImageCache.shared.image(for: URL(string:imageSource))
        }
    }
    
    enum SpendCodingKeys: String, CodingKey {
        case title
        case description
        case image
        case confirmation
        case amount
    }
    
    required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: SpendCodingKeys.self)
        let titleString = try values.decode(String.self, forKey: .title)
        let descriptionString = try values.decode(String.self, forKey: .description)
        imageSource = try values.decode(String.self, forKey: .image)
        confirmation = try values.decodeIfPresent(SpendViewModel.self, forKey: .confirmation)
        amount = try values.decodeIfPresent(Int32.self, forKey: .amount)
        description = descriptionString.attributed(14.0, weight: .regular, color: .kinBlueGreyTwo)
        buttonLabel = "kinecosystem_confirm".localized().attributed(16.0, weight: .regular, color: .kinWhite)
        if confirmation != nil {
            guard let amount = amount else { throw KinError.internalInconsistency }
            title = (titleString + " - ").attributed(22.0, weight: .regular, color: .kinBlueGrey) +
            "\(Decimal(amount).currencyString()) Kin".attributed(22.0, weight: .regular, color: .kinDeepSkyBlue)
        } else {
            title = titleString.attributed(22.0, weight: .regular, color: .kinBlueGrey)
        }
    }
}
