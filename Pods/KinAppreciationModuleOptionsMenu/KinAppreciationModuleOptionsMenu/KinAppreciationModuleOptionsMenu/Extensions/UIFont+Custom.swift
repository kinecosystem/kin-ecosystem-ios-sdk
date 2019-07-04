//
//  UIFont+Custom.swift
//  KinAppreciationModuleOptionsMenu
//
//  Created by Corey Werner on 24/06/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import UIKit

extension UIFont {
    static func registerFont(fontName: String, fontExtension: String) {
        guard let fontURL = Bundle.appreciation.url(forResource: fontName, withExtension: fontExtension) else {
            return
        }

        guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL) else {
            return
        }

        guard let font = CGFont(fontDataProvider) else {
            return
        }

        CTFontManagerRegisterGraphicsFont(font, nil)
    }
}
