//
//  KinNetwork.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 30/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinSDK
import KinCoreSDK
import StellarKit

public enum Network {
    case mainNet
    case testNet
    case playground
    case custom(issuer: String, networkId: String)
}

extension Network {
    var mapToKinCore: KinCoreSDK.NetworkId {
        switch self {
        case .mainNet:
            return .mainNet
        case .testNet:
            return .testNet
        case .playground:
            return .playground
        case .custom(let issuer, let networkId):
            return .custom(issuer: issuer, stellarNetworkId: StellarKit.NetworkId(networkId))
        }
    }

    var mapToKinSDK: KinSDK.Network {
        switch self {
        case .mainNet:
            return .mainNet
        case .testNet:
            return .testNet
        case .playground:
            return .playground
        case .custom(_, let networkId):
            return .custom(networkId)
        }
    }

    public var kinCoreId: String {
        return mapToKinCore.stellarNetworkId.description
    }

    public var kinSDKId: String {
        return mapToKinSDK.id
    }

    public var kinCoreIssuer: String {
        return mapToKinCore.issuer
    }
}

extension Network: CustomStringConvertible {
    /// :nodoc:
    public var description: String {
        return mapToKinSDK.description
    }
}

extension Network: Equatable {
    public static func ==(lhs: Network, rhs: Network) -> Bool {
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
        case .custom:
            return false
        }
    }
}
