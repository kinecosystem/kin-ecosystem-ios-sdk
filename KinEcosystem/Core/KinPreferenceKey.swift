//
//  KinPreferenceKey.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 23/05/2018.
//

import Foundation

enum KinPreferenceKey: String, CodingKey {
    case tosAccepted
    case ecosystemUUID
    case authToken
    case lastBalance
    case lastSignedInUser
    case firstSpendSubmitted
    case lastEnvironment
}
