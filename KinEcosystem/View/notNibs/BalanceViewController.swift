//
//  BalanceViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 04/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinMigrationModule

@available(iOS 9.0, *)
class BalanceViewController: KinViewController {

    var core: Core!
    @IBOutlet weak var balanceAmount: UILabel!
    @IBOutlet weak var balance: UILabel!
    let themeLinkBag = LinkBag()
    var theme: Theme?
    fileprivate var selected = false
    fileprivate let bag = LinkBag()

    
    
    convenience init(core: Core) {
        self.init(nibName: "BalanceViewController", bundle: KinBundle.ecosystem.rawValue)
        self.core = core
        loadViewIfNeeded()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        let lastBalance = Kin.shared.lastKnownBalance
        core.blockchain.balanceObservable.on(queue: .main, next: { [weak self] balance in
            guard let this = self, let theme = this.theme else { return }
            this.balanceAmount.attributedText = "\(balance.amount)".styled(as: theme.balanceAmount).kin
        }).add(to: bag)
        core.blockchain.balance().then { balance in
            if let oldBalance = lastBalance,
                oldBalance.amount != balance,
                Kin.shared.isActivated {
                Kin.shared.updateData(with: OrdersList.self, from: "orders").error { error in
                        logError("data sync failed (\(error))")
                }
            }
        }
        
    }

    

    

}

extension BalanceViewController: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        balance.attributedText = "balance".localized().styled(as: theme.title18)
    }
}
