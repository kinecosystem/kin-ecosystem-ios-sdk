//
//  KinBaseNavigationController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 19/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class KinBaseNavigationController: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var navigationBar: UINavigationBar {
        let bar = super.navigationBar
        bar.isTranslucent = false
        let colors = [UIColor.kinAzure, UIColor.kinBrightBlueTwo]
        bar.applyNavigationGradient(colors: colors)
        bar.titleTextAttributes = [.foregroundColor: UIColor.white]
        return bar
    }

    override var edgesForExtendedLayout: UIRectEdge {
        get { return [] }
        set { super.edgesForExtendedLayout = newValue }
    }
}
