//
//  DeviceData.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 01/07/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import AdSupport

struct DeviceData {
    static var deviceId: String {
        var identifier = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let letters = NSCharacterSet.letters
        if identifier.rangeOfCharacter(from: letters) == nil {
            if let vendorIdentifier = UIDevice.current.identifierForVendor?.uuidString {
                identifier = vendorIdentifier
            } else if let uuid = UserDefaults.standard.string(forKey: KinPreferenceKey.ecosystemUUID.rawValue) {
                identifier = uuid
            } else {
                let uuid = UUID().uuidString
                UserDefaults.standard.set(uuid, forKey: KinPreferenceKey.ecosystemUUID.rawValue)
                identifier = uuid
            }
        }
        return identifier
    }
}
