//
//  NoOffersViewController.swift
//  KinEcosystem
//
//  Created by Natan Rolnik on 25/06/19.
//

import UIKit
import KinUtil

class NoOffersViewController: UIViewController {
    let themeLinkBag = LinkBag()
    @IBOutlet weak var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTheming()
    }
}

extension NoOffersViewController: Themed {
    func applyTheme(_ theme: Theme) {
        titleLabel.attributedText = "kinecosystem_empty_well_done"
            .localized()
            .styled(as: theme.title20)
            .applyingTextAlignment(.center)
    }
}
