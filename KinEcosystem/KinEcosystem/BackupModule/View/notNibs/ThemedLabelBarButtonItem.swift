//
//  ThemedLabelBarButtonItem.swift
//  KinEcosystem
//
//  Created by Natan Rolnik on 20/06/19.
//

import UIKit
import KinUtil

class ThemedLabelBarButtonItem: UIBarButtonItem, Themed {
    let themeLinkBag = LinkBag()
    private let label = UILabel()

    convenience init(text: String) {
        self.init()

        label.text = text
        label.font = Font(name: "Sailec-Regular", size: 14)

        customView = label

        setupTheming()
    }

    func applyTheme(_ theme: Theme) {
        label.textColor = theme.mainTintColor
    }
}

