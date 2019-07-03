//
//  Asset.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

public enum Asset: Int32 {
    case native = 0
}

extension Asset: XDRCodable {
    public init(from decoder: XDRDecoder) throws {
        _ = try decoder.decode(UInt32.self)
        self = .native
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(Asset.native.rawValue)
    }
}

extension Asset: CustomStringConvertible {
    public var description: String {
        return "native"
    }
}
