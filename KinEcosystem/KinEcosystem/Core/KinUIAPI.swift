//
//  KinUIAPI.swift
//  KinEcosystem
//
//  Created by MNM on 10/07/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit
public enum PromptType { case balanceChange }
public struct KinUIAPI {
    static private var balanceObserverId:String?
    static private var promptTypes:[PromptType]?
    static private var lastBalance:Decimal = 0
    static private var formatter:NumberFormatter = NumberFormatter()
    private static var doOnce:()->() = {
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        formatter.currencyCode = ""
        return {}
    }()
    static public func enablePrompt(for types:[PromptType]) {
        doOnce()
        disablePrompt()
        promptTypes = types
        promptTypes?.forEach { type in
            switch type {
            case .balanceChange:
                balanceObserverId = Kin.shared.addBalanceObserver { balance in
                    DispatchQueue.main.async {
                        if balance.amount != lastBalance {
                            lastBalance = balance.amount
                            Prompt.show(title: "Balance", message: formatter.string(from:NSNumber(value: Double(truncating:  balance.amount as NSNumber))) ?? "0",timeout:4.0)
                        }
                    }
                }
                break
            }
        }
    }
    static public func disablePrompt() {
        if let balanceObserverId = balanceObserverId {
            Kin.shared.removeBalanceObserver(balanceObserverId)
        }
        promptTypes = nil
    }
    static public func dismissCurrentPrompt() {
        Prompt.hide()
    }
}
