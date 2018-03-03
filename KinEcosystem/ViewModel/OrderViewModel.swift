//
//  OrderViewModel.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 01/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

class OrderViewModel {
    
    let id: String
    let title: NSAttributedString
    let subtitle: NSAttributedString
    let amount: NSAttributedString
    
    init(with model: Order) {
        // TODO: include call for action / text per order status / define
        title = NSAttributedString(string: model.title, attributes:
            [.font : UIFont.systemFont(ofSize: 18.0, weight: .regular),
             .foregroundColor : UIColor.kinBlueGrey])
        subtitle = NSAttributedString(string: model.description_, attributes:
            [.font : UIFont.systemFont(ofSize: 14.0, weight: .regular),
             .foregroundColor : UIColor.kinBlueGreyTwo])
        id = model.id
        let amountString = (model.offerType == .earn ? "+" : "-") + "\(model.amount)"
        amount = NSAttributedString(string: amountString, attributes:
            [.font : UIFont.systemFont(ofSize: 16.0, weight: .medium),
             .foregroundColor : UIColor.kinBlueGreyTwo])
    }
}
