//
//  KinUIAPI.swift
//  KinEcosystem
//
//  Created by Alon Genosar on 10/07/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit
public struct PromptType: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let balanceChange = PromptType(rawValue: 1 << 0)
    public static let all:PromptType = [.balanceChange]
}
public struct KinUIAPI {
    static private var balanceObserverId:String?
    static private var promptTypes:PromptType?
    static private var lastBalance:Decimal = 0
    static private var formatter:NumberFormatter = NumberFormatter()
    private static var doOnce:()->() = {
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        formatter.currencyCode = ""
        return {}
    }()
    static private var callback:( (PromptType,PromptCallbackAction) -> Void )?
    static public func enablePrompt(for types:PromptType,_ callback:((PromptType,PromptCallbackAction)->Void)? = nil) {
        doOnce()
        disablePrompt()
        promptTypes = types
        if promptTypes!.contains(.balanceChange) {
            balanceObserverId = Kin.shared.addBalanceObserver { balance in
                DispatchQueue.main.async {
                    if balance.amount != lastBalance {
                        lastBalance = balance.amount
                        Prompt.show(title: "Balance", message: formatter.string(from:NSNumber(value: Double(truncating:  balance.amount as NSNumber))) ?? "0",timeout:4.0,config: .hasCloseButton) { action in
                            callback?(.balanceChange,action)
                        }
                    }
                }//Add ispatchQueue.main.async
            }//End balance observer block
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

class BalancePrompt: UIView {
    @IBOutlet var closeButton:UIButton!
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var messageLabel:UILabel!
    private var callback:PromptCallback?
    private var config:PromptConfig?
}
