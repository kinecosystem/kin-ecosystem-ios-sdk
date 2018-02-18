//
//  UINavigationBar+gradient.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 19/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
extension UINavigationBar
{
    func applyNavigationGradient( colors : [UIColor]) {
        var frameAndStatusBar: CGRect = self.bounds
        frameAndStatusBar.size.height += 20
        setBackgroundImage(UINavigationBar.gradient(size: frameAndStatusBar.size, colors: colors), for: .default)
    }
    
    static func gradient(size : CGSize, colors : [UIColor]) -> UIImage? {
        let cgcolors = colors.map { $0.cgColor }
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        defer { UIGraphicsEndImageContext() }
        var locations : [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgcolors as NSArray as CFArray, locations: &locations) else { return nil }
        context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: size.width, y: size.height), options: [])
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
