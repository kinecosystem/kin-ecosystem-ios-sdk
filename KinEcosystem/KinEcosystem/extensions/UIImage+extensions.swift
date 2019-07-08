//
//  UIImage+extensions.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 08/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    class func bundleImage(_ name: String) -> UIImage? {
        return UIImage(named: name, in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
    }

    func overlayed(with image: UIImage?) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(at: .zero)

        image?.draw(at: .zero)

        defer {
            UIGraphicsEndImageContext()
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func padded(with insets: UIEdgeInsets) -> UIImage? {
        let paddedSize = CGSize(width: size.width + insets.left + insets.right, height:size.height + insets.top + insets.bottom)
        UIGraphicsBeginImageContextWithOptions(paddedSize, false, 0.0)
        self.draw(at: CGPoint(x: insets.left, y: insets.top))
        defer {
            UIGraphicsEndImageContext()
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func tinted(with color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        defer {
            UIGraphicsEndImageContext()
        }

        return newImage?.resizableImage(withCapInsets: capInsets, resizingMode: resizingMode) ?? self
    }
}
