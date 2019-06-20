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
    let last: Bool
    let first: Bool
    let theme: Theme
    let icon: UIImage?
    
    init(with model: Order, theme: Theme, last: Bool, first: Bool) {
        self.theme = theme
        self.last = last
        self.first = first
        id = model.id
        let details: String
        
        switch model.offerType {
        case .spend:
            switch model.orderStatus {
            case .completed:
                if let action = model.call_to_action {
                    details = " - " + action
                } else {
                    details =  ""
                }
            case .failed:
                details = " - " + (model.error?.error ?? "kinecosystem_transaction_failed".localized())
            default:
                details = ""
            }
        default:
            details = ""
        }
        title = model.title.styled(as: theme.title18) +
                details.styled(as: theme.title18)
        var subtitleString = model.description_
        if let shortDate = Iso8601DateFormatter.shortString(from: model.completion_date as Date) {
            subtitleString = subtitleString + " - " + shortDate
        }
        subtitle = subtitleString.styled(as: theme.lightSubtitle14)
        
        if case .earn = model.offerType {
            icon = UIImage.bundleImage(first ? "kinEarnIconActive" : "kinIconInactive")
            amount = "+\(model.amount)".styled(as: first ? theme.historyRecentEarnAmount : theme.historyAmount)
        } else {
            icon = UIImage.bundleImage(first ? "kinSpendIconActive" : "kinIconInactive")
            amount = "-\(model.amount)".styled(as: first ? theme.historyRecentSpendAmount : theme.historyAmount)
        }
        
        
        
    }
}
