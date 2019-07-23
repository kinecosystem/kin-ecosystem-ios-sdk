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
    let model: Offer
    let theme: Theme

    private var title: NSAttributedString {
        let cellTitle = model.title
        var attributed: NSAttributedString!
        if case .earn = model.offerType {
            attributed = cellTitle.styled(as: theme.earnTitle)
        } else {
            attributed = cellTitle.styled(as: theme.spendTitle)
        }
        return attributed
    }
    
    private var priceTitle: NSAttributedString {
        if case .earn = model.offerType {
           return  " +".styled(as: theme.earnTitle) + "\(model.amount)".styled(as: theme.earnTitle).kinPrefixed()
        } else {
             return  " ".styled(as: theme.spendTitle) + "\(model.amount)".styled(as: theme.spendTitle).kinPrefixed()
          // return  " \(model.amount)".styled(as: theme.spendTitle).kinPrefixed()
        }
    }

    private var subtitle: NSAttributedString {
        return model.description_.styled(as: theme.offerDetails)
    }
    
    private var image: Promise<ImageCacheResult> {
        get {
            return ImageCache.shared.image(for: URL(string: model.image))
        }
    }
    
    private var cellBorderColor: UIColor {
        return theme.cellBorderColor
    }
    
    
    init(with model: Offer, theme: Theme) {
        self.model = model
        self.theme = theme
    }
    
    func setup(_ cell: OfferCell) {
        cell.layer.cornerRadius = 5.0
        cell.layer.borderWidth = 1.0
        cell.layer.borderColor = theme.cellBorderColor.cgColor
       // print(title.atri)

        cell.offerTitle.attributedText = title
        cell.offerText.attributedText = subtitle
        cell.priceLabel.attributedText = priceTitle
        image.then(on: .main) { [weak cell] result in
            cell?.offerImageView.image = result.image
        }.error { error in
                logError("error in offer cell image fetch: \(error.localizedDescription)")
        }
    }
}
