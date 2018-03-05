//
//  BalanceView.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 01/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import UIKit
import KinUtil
import KinSDK

class BalanceView : UIView {
    
    @IBOutlet weak var balanceAmount: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var rightAmountConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightArrowImage: UIImageView!
    
    fileprivate var selected = false
    private var watch: BalanceWatch?
    fileprivate let linkBag = LinkBag()
    var core: Core!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        watchBalance()
    }
    
    fileprivate func watchBalance() {
//        watch = try? core.blockchain.account.watchBalance()
//        watch?.emitter.on(queue: .main, next: { [weak self] balance in
//            self?.balanceAmount.text = balance.balance.currencyString()
//        }).on(error: { error in
//            logWarn("showing zero for balance because real balance retrieve failed with error: \(error)")
//        })
//        .add(to: linkBag)
    }
    
    func setSelected(_ selected: Bool, animated: Bool) {
        guard self.selected != selected else { return }
        
        self.selected = selected
        
        self.rightAmountConstraint.constant = selected ? 0.0 : 20.0
        let block = {
            self.rightArrowImage.alpha = selected ? 0.0 : 1.0
            self.layoutIfNeeded()
        }
        
        guard animated else {
            block()
            return
        }
        
        UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration)) {
            block()
        }
    }
}
