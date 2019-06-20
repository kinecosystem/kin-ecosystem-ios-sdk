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
        return UIImage(named: name, in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
    }
    
    func overlayed(with image: UIImage?) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(at: .zero)
        if let image = image {
            image.draw(at: .zero)
        }
        let ol = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return ol
    }
    
    func padded(with insets: UIEdgeInsets) -> UIImage? {
        let paddedSize = CGSize(width: size.width + insets.left + insets.right, height:size.height + insets.top + insets.bottom)
        UIGraphicsBeginImageContextWithOptions(paddedSize, false, 0.0)
        self.draw(at: CGPoint(x: insets.left, y: insets.top))
        let pd = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return pd
    }
    
}
