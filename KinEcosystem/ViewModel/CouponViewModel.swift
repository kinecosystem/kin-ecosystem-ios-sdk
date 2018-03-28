//
//  CouponViewModel.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

import KinUtil
import KinSDK

class CouponViewModel: Decodable {
    
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
    var code: NSAttributedString?
    
    enum CouponCodingKeys: String, CodingKey {
        case title
        case description
        case image
        case link
    }
    
    required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CouponCodingKeys.self)
        
        let titleString = try values.decode(String.self, forKey: .title)
        let descriptionString = try values.decode(String.self, forKey: .description)
        let linkString = try values.decode(String.self, forKey: .link)
        imageSource = try values.decode(String.self, forKey: .image)
        
        title = titleString.attributed(22.0, weight: .regular, color: .kinBlueGrey)
        description = (descriptionString + " ").attributed(14.0, weight: .regular, color: .kinBlueGrey) +
                        linkString.attributed(14.0, weight: .regular, color: .kinDeepSkyBlue)
        buttonLabel = "Copy Code".attributed(16.0, weight: .regular, color: .kinWhite)
    }
}
