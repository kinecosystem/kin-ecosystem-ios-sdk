//
//  StatusBarStyle+Color.swift
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
