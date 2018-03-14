//
//  BalanceViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 04/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinSDK
import KinUtil

class BalanceViewController: UIViewController {

    var core: Core!
    @IBOutlet weak var balanceAmount: UILabel!
    @IBOutlet weak var balance: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var rightAmountConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightArrowImage: UIImageView!
    
    fileprivate var selected = false
    fileprivate var watch: BalanceWatch!
    fileprivate let bag = LinkBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.global().async { [weak self] in
            guard let this = self else { return }
            let balance = try? this.core.blockchain.account.balance()
            this.watch = try? this.core.blockchain.account.watchBalance(balance ?? 0)
            this.watch?.emitter.on(queue: .main, next: { balance in
                logInfo("balance updated: \(balance.currencyString())")
                this.balanceAmount.attributedText = "\(balance.currencyString())".attributed(24.0, weight: .regular, color: .kinDeepSkyBlue)
            })
            .add(to: this.bag)
        }
        
    }
    
    func setSelected(_ selected: Bool, animated: Bool) {
        guard self.selected != selected else { return }
        
        self.selected = selected
        
        self.rightAmountConstraint.constant = selected ? 0.0 : 20.0
        let block = {
            self.rightArrowImage.alpha = selected ? 0.0 : 1.0
            self.view.layoutIfNeeded()
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
