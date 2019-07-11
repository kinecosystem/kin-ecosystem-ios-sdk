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
                        if let window = UIApplication.shared.keyWindow {
                            let balanceView = BalancePrompt(
                                frame:CGRect(x:10,y:UIApplication.shared.statusBarFrame.height + 5,width:window.frame.width - 20,height:70),
                                title: "Balance",
                                message: formatter.string(from:NSNumber(value: Double(truncating:  balance.amount as NSNumber))) ?? "0",
                                config: [.closeOnTap,.hasCloseButton])
                            Prompt.show(view: balanceView)
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
struct PromptConfig: OptionSet {
    let rawValue: Int
    static let hasCloseButton = PromptConfig(rawValue: 1 << 0)
    static let closeOnTap = PromptConfig(rawValue: 1 << 1)
    static let all:PromptConfig = [.closeOnTap]
}
class BalancePrompt: UIView {
    @IBOutlet var closeButton:UIButton!
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var messageLabel:UILabel!
    private var callback:PromptCallback?
    private var config:PromptConfig?
    var content:UIView?
    init(frame: CGRect,title:String?,message:String?,config:PromptConfig? = nil) {
        super.init(frame: frame)
        self.config = config
        content = Bundle(for: Kin.self).loadNibNamed("BalancePrompt", owner: self, options: nil)?.first as? UIView
        titleLabel.text = title
        closeButton.isHidden = !(config?.contains(.hasCloseButton) ?? false) ?? true
        messageLabel.text = message
        messageLabel.sizeToFit()
        addSubview(content!)
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        content?.frame = bounds
    }
    @IBAction func handleTap(_ gr:UITapGestureRecognizer) {
        if config?.contains(.closeOnTap) ?? false {
            Prompt.hide(self,animate:true)
        }
    }
    @IBAction func handleCloseButtonTap(_ gr:UIButton) {
        Prompt.hide(self,animate:true)
    }
}
