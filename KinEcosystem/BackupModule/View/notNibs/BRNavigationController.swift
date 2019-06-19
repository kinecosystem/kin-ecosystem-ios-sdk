//
//  BRNavigationController.swift
//  KinEcosystem
//
//  Created by Natan Rolnik on 17/06/19.
//

import UIKit
import KinUtil

class BRNavigationController: UINavigationController {
    let themeLinkBag = LinkBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTheming()
    }
}

extension BRNavigationController: Themed {
    func applyTheme(_ theme: Theme) {
        navigationBar.titleTextAttributes = theme.title18.attributes
        navigationBar.tintColor = theme.closeButtonTint
    }
}
