//
//  Xib+localization.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 08/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
protocol XIBLocalizable {
    var xibLocKey: String? { get set }
}

extension UILabel: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set(key) {
            text = key?.localized()
        }
    }
}
extension UIButton: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set(key) {
            setTitle(key?.localized(), for: .normal)
        }
    }
}
