//
//  BRNavigationController.swift
//  KinEcosystem
//
//  Created by Natan Rolnik on 17/06/19.
//

import UIKit
import KinUtil

class ThemedNavigationController: UINavigationController {
    let themeLinkBag = LinkBag()
    var theme: Theme = .light
    var showBackWithoutText = true

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.preferredStatusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTheming()
        delegate = self
    }
}

extension ThemedNavigationController: Themed {
    func applyTheme(_ theme: Theme) {
        navigationBar.titleTextAttributes = theme.title18.attributes
        navigationBar.tintColor = theme.mainTintColor
    }
}

extension ThemedNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if showBackWithoutText {
            viewController.navigationItem.backBarButtonItem = .init(title: " ", style: .plain, target: nil, action: nil)
        }
    }
}
