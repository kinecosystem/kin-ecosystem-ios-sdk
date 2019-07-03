//
//  CouponViewModel.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

import KinUtil
import KinCoreSDK
@available(iOS 9.0, *)
class CouponViewModel: Decodable {
    
    var title: NSAttributedString
    var description: NSMutableAttributedString
    fileprivate var imageSource: String
    var confirmation: SpendViewModel?
    var buttonLabel: NSAttributedString?
    var amount: Int32?
    var image: Promise<ImageCacheResult> {
        get {
            return ImageCache.shared.image(for: URL(string:imageSource))
        }
    }
    var coupon_code: String?
    var code: NSAttributedString {
        get {
            return (coupon_code ?? "").attributed(16.0, weight: .regular, color: .kinBlueGreyTwo)
        }
    }
    
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
        let nsDescriptionString = description.string as NSString
        let linkRange = nsDescriptionString.range(of: linkString)
        if linkRange.location != NSNotFound {
            description.addAttribute(.link, value: linkString, range: linkRange)
        }
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        description.addAttribute(.paragraphStyle, value: pStyle, range: NSMakeRange(0, description.string.count))
        buttonLabel = "kinecosystem_copy_code".localized().attributed(16.0, weight: .regular, color: .kinWhite)
    }
}
