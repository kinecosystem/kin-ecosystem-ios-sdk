//
//  NetworkId.swift
//  KinCoreSDK
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit

/**
 `NetworkId` represents the block chain network to which `KinClient` will connect.
 */
public enum NetworkId {
    /**
     Kik's private Stellar production network.
     */
    case mainNet

    /**
     Kik's private Stellar test network.
     */
    case testNet

    /**
     Kik's private Stellar playground network.
     */
    case playground

    /**
     A network with a custom issuer and Stellar sidentifier.
     */
    case custom(issuer: String, stellarNetworkId: StellarKit.NetworkId)
}

extension NetworkId {
    public var issuer: String {
        switch self {
        case .mainNet:
            return "GDF42M3IPERQCBLWFEZKQRK77JQ65SCKTU3CW36HZVCX7XX5A5QXZIVK"
        case .testNet:
            return "GBC3SG6NGTSZ2OMH3FFGB7UVRQWILW367U4GSOOF4TFSZONV42UJXUH7"
        case .playground:
            return "GBC3SG6NGTSZ2OMH3FFGB7UVRQWILW367U4GSOOF4TFSZONV42UJXUH7"
        case .custom (let issuer, _):
            return issuer
        }
    }

    public var stellarNetworkId: StellarKit.NetworkId {
        switch self {
        case .mainNet:
            return StellarKit.NetworkId("Public Global Kin Ecosystem Network ; June 2018")
        case .testNet:
            return StellarKit.NetworkId("Kin Playground Network ; June 2018")
        case .playground:
            return StellarKit.NetworkId("Kin Playground Network ; June 2018")
        case .custom(_, let stellarNetworkId):
            return stellarNetworkId
        }
    }
}

extension NetworkId: CustomStringConvertible {
    /// :nodoc:
    public var description: String {
        switch self {
        case .mainNet:
            return "main"
        case .testNet:
            return "test"
        case .playground:
            return "playground"
        default:
            return "custom network"
        }
    }
}

extension NetworkId: Equatable {
    public static func ==(lhs: NetworkId, rhs: NetworkId) -> Bool {
        switch lhs {
        case .mainNet:
            switch rhs {
            case .mainNet:
                return true
            default:
                return false
            }
        case .testNet:
            switch rhs {
            case .testNet:
                return true
            default:
                return false
            }
        case .playground:
            switch rhs {
            case .playground:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
