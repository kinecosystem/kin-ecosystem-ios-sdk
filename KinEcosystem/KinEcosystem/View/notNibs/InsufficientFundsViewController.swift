//
//  InsufficientFundsViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 11/04/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinUtil

class InsufficientFundsViewController: UIViewController {
    let themeLinkBag = LinkBag()
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var goButton: KinButton!
    @IBOutlet weak var cancelButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTheming()
        Kin.track { try NotEnoughKinPageViewed() }

        let balanceView = BalanceView()
        balanceView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(balanceView)
        cancelButton.centerYAnchor.constraint(equalTo: balanceView.centerYAnchor).isActive = true
        view.centerXAnchor.constraint(equalTo: balanceView.centerXAnchor).isActive = true

    }

    @IBAction func goTapped(_ sender: Any) {
        close()
    }

    @IBAction func closeTapped(_ sender: Any) {
        close()
    }
    
    func close() {
        dismiss(animated: true)
    }
}

extension InsufficientFundsViewController: Themed {
    func applyTheme(_ theme: Theme) {
        titleLabel.attributedText = "kinecosystem_you_dont_have_enough_kin"
            .localized()
            .styled(as: theme.title20)
        descriptionLabel.attributedText = "kinecosystem_you_dont_have_enough_kin_subtitle"
            .localized()
            .styled(as: theme.subtitle14)
        let buttonTitle = "kinecosystem_goto_earn_section"
            .localized()
            .styled(as: theme.buttonTitle)
        goButton.setAttributedTitle(buttonTitle, for: .normal)
    }
}
