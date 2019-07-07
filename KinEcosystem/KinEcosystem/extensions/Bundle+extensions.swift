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

extension Bundle {
    class var ecosystem: Bundle {
        let bundle = Bundle(for: Kin.self)

        if  let bundlePath = bundle.path(forResource: "KinEcosystem", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath) {
            return bundle
        }
        return bundle
    }
    
    class var kinLocalization: Bundle {
        let bundle = Bundle(for: Kin.self)
        if  let bundlePath = bundle.path(forResource: "kinLocalization", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath) {
            return bundle
        }
        return bundle
    }

    static var appName: String? {
        return main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? main.infoDictionary?["CFBundleName"] as? String
    }
}
