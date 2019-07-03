//
//  Appearance.swift
//  KinAppreciationModuleOptionsMenu
//
//  Created by Corey Werner on 19/06/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

protocol ThemeProtocol {
    var theme: Theme { get set }
    func updateTheme()
}

public enum Theme {
    case light
    case dark
}

extension UIColor {
    static let kinPurple = UIColor(red: 111/255, green: 65/255, blue: 232/255, alpha: 1)
    static let kinGreen = UIColor(red: 29/255, green: 194/255, blue: 164/255, alpha: 1)

    static let gray31 = UIColor(white: 31/255, alpha: 1)
    static let gray51 = UIColor(white: 51/255, alpha: 1)
    static let gray88 = UIColor(white: 88/255, alpha: 1)
    static let gray140 = UIColor(white: 140/255, alpha: 1)
    static let gray222 = UIColor(white: 222/255, alpha: 1)
}

extension UIFont {
    static let custom = CustomFont()

    static func sailecFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont? {
        switch weight {
        case .medium, .semibold, .bold, .heavy, .black:
            return UIFont(name: "Sailec-Medium", size: size)

        case .ultraLight, .thin, .light, .regular:
            fallthrough
        default:
            return UIFont(name: "Sailec-Regular", size: size)
        }
    }
}

class CustomFont {
    private var didLoad = false

    func loadFontsIfNeeded() {
        guard !didLoad else {
            return
        }

        didLoad = true

        UIFont.registerFont(fontName: "Sailec", fontExtension: "otf")
        UIFont.registerFont(fontName: "SailecMedium", fontExtension: "otf")
    }
}
