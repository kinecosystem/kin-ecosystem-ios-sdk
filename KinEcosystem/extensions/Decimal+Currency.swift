//
//  Decimal+Currency.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 19/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

extension Decimal {
    
    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = ""
        f.usesGroupingSeparator = true
        f.maximumFractionDigits = 0
        f.groupingSeparator = ","
        return f
    }()
    
    func currencyString() -> String {
        if let formattedString = Decimal.currencyFormatter.string(from: self as NSDecimalNumber) {
            return formattedString
        }
        return "\(self)"
    }
}
