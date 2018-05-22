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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = false
        let colors = [UIColor.kinAzure, UIColor.kinBrightBlueTwo]
        navigationBar.applyNavigationGradient(colors: colors)
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    }

    override var edgesForExtendedLayout: UIRectEdge {
        get { return [] }
        set { super.edgesForExtendedLayout = newValue }
    }
}
