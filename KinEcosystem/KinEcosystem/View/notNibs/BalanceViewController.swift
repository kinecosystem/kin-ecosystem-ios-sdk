//
//  BalanceViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 04/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinMigrationModule

class BalanceViewController: KinViewController {
    var core: Core!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    fileprivate(set) var balance = Balance(amount: 0) {
        didSet {
            updateBalance(balance)
        }
    }

    let themeLinkBag = LinkBag()
    var theme: Theme = .light
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
            guard let self = self else { return }
            self.balance = balance
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

    fileprivate func updateBalance(_ balance: Balance) {
        let attributedText = NSMutableAttributedString(attributedString:  "\(balance.amount)".styled(as: theme.balanceAmount).kinPrefixed(with: textColor))
        amountLabel.attributedText = attributedText
    }

    var textColor: UIColor {
        guard let color = theme.balanceAmount.attributes[.foregroundColor] as? UIColor else {
            return .black
        }

        return color
    }
}

extension BalanceViewController: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        titleLabel.attributedText = "balance".localized().styled(as: theme.title18)
        updateBalance(balance)
    }
}
