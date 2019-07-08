//
//  UIStatusBarStyle+Appearance.swift
//  KinEcosystem
//
//  Created by Corey Werner on 23/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

extension UIStatusBarStyle {
    var color: UIColor {
        switch self {
        case .default:
            return .black
        case .lightContent:
            return .white
        }
    }
}

extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if let topViewController = topViewController, topViewController is BRViewController {
            return topViewController.preferredStatusBarStyle
        }
        return super.preferredStatusBarStyle
    }
}
