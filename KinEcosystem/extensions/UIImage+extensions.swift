//
//  UIImage+extensions.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 08/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 9.0, *)
extension UIImage {
    class func bundleImage(_ name: String) -> UIImage? {
        return UIImage(named: name, in: Bundle.ecosystem, compatibleWith: nil)
    }
}
