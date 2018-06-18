//
//  Balance.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 06/06/2018.
//

import Foundation

public struct Balance: Codable, Equatable {
    public var amount: Decimal

    public static func ==(lhs: Balance, rhs: Balance) -> Bool {
        return lhs.amount == rhs.balance
    }
}
