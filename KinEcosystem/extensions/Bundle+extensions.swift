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

@available(iOS 9.0, *)
extension Bundle {
    class var ecosystem: Bundle {
        let bundle = Bundle(for: Kin.self)
        if  let bundlePath = bundle.path(forResource: "KinEcosystem", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath) {
            return bundle
        }
        return bundle
    }
}
