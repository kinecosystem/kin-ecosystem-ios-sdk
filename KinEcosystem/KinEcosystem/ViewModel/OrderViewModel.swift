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
    var title: NSAttributedString
    let subtitle: NSAttributedString
    var amount: NSAttributedString
    var failed: NSAttributedString
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

        failed = "".styled(as: theme.title18Error)
        title = model.title.styled(as: theme.title18)
        icon = UIImage.bundleImage(first ? "kinSpendIconActive" : "kinIconInactive")

        switch model.offerType {
        case .spend:
            switch model.orderStatus {
            case .completed:
                if let action = model.call_to_action {
                    details = " - " + action
                } else {
                    details =  ""
                }
               title = model.title.styled(as: theme.title18) + details.styled(as: theme.title18)
               amount = "-\(model.amount)".styled(as: first ? theme.historyRecentSpendAmount : theme.historyAmount)
            break
            case .failed:
                failed = " - ".styled(as: theme.title18) + "kinecosystem_transaction_failed".localized().styled(as: theme.title18Error)
                amount = "kinecosystem_transaction_failed".localized().styled(as: theme.title18Error) + "\(model.amount)".styled(as: first ? theme.historyRecentSpendAmount : theme.historyAmount)
            default:
                amount = "-\(model.amount)".styled(as: first ? theme.historyRecentSpendAmount : theme.historyAmount)
            }
        default:
            amount = "+\(model.amount)".styled(as: first ? theme.historyRecentEarnAmount : theme.historyAmount)
        }

        var subtitleString = model.description_
        if let shortDate = Iso8601DateFormatter.shortString(from: model.completion_date as Date) {
            subtitleString = subtitleString + " - " + shortDate
        }

        subtitle = subtitleString.styled(as: theme.lightSubtitle14)
    }
}
