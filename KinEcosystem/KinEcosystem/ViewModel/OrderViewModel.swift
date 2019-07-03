//
//  OrderViewModel.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 01/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
class OrderViewModel {
    
    let id: String
    let title: NSAttributedString
    let subtitle: NSAttributedString
    let amount: NSAttributedString
    let image: UIImage?
    let last: Bool
    let color: UIColor
    
    init(with model: Order, last: Bool) {
        self.last = last
        id = model.id
        let details: String
        var indicatorColor: UIColor = .kinLightBlueGrey
        var titleColor: UIColor = .kinBlueGrey
        var detailsColor: UIColor = .kinDeepSkyBlue
        switch model.offerType {
        case .spend:
            image = UIImage(named: "invoice", in: Bundle.ecosystem, compatibleWith: nil)
            switch model.orderStatus {
            case .completed:
                indicatorColor = .kinDeepSkyBlue
                titleColor = .kinDeepSkyBlue
                if let action = model.call_to_action {
                    details = " - " + action
                } else {
                    details =  ""
                }
            case .failed:
                indicatorColor = .kinWatermelon
                detailsColor = .kinWatermelon
                details = " - " + (model.error?.error ?? "kinecosystem_transaction_failed".localized())
            default:
                details = ""
            }
        default:
            image = UIImage(named: "coins", in: Bundle.ecosystem, compatibleWith: nil)
            details = ""
        }
        color = indicatorColor
        title = model.title.attributed(18.0, weight: .regular, color: titleColor) +
                details.attributed(14.0, weight: .regular, color: detailsColor)
        var subtitleString = model.description_
        if let shortDate = Iso8601DateFormatter.shortString(from: model.completion_date as Date) {
            subtitleString = subtitleString + " - " + shortDate
        }
        subtitle = subtitleString.attributed(14.0, weight: .regular, color: .kinBlueGreyTwo)
        
        amount = ((model.offerType == .earn ? "+" : "-") + "\(Decimal(model.amount).currencyString()) ").attributed(16.0, weight: .medium, color: .kinBlueGreyTwo)

        
    }
}
