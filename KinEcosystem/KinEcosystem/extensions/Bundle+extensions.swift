//
//
//  Bundle+extensions.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//

import Foundation

enum KinBundle: RawRepresentable {
    init?(rawValue: Bundle) {
        return nil
    }
    
    var rawValue: Bundle {
        get {
            switch self {
            case .ecosystem:
                return Bundle.kinBundleNamed("KinEcosystem")
            case .localization:
                return Bundle.kinBundleNamed("kinLocalization")
            case .fonts:
                return Bundle.kinBundleNamed("kinFonts")
            }
        }
    }
    
    typealias RawValue = Bundle

    case ecosystem
    case localization
    case fonts
}

extension Bundle {
    fileprivate class func kinBundleNamed(_ name: String) -> Bundle {
        let mainFrameworkBundle = Bundle(for: Kin.self)
        if
            let bundlePath = mainFrameworkBundle.path(forResource: name, ofType: "bundle"),
            let bundle = Bundle(path: bundlePath) {
            return bundle
        }

        return mainFrameworkBundle
    }

    static var appName: String? {
        return main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? main.infoDictionary?["CFBundleName"] as? String
    }
}
