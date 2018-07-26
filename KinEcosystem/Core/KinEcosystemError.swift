//
//  KinEcosystemError.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 29/05/2018.
//

import Foundation
import KinCoreSDK

public enum KinClientErrorCode: Int {
    case notStarted             = 4001
    case badRequest             = 4002
    case internalInconsistency  = 4003
}

public enum KinServiceErrorCode: Int {
    case response               = 5001
    case network                = 5002
    case timeout                = 5003
}

public enum KinBlockchainErrorCode: Int {
    case creation               = 6001
    case notFound               = 6002
    case activation             = 6003
    case insufficientFunds      = 6004
    case txFailed               = 6005
}

public enum KinUnknownErrorCode: Int {
    case unknown                = 9999
}

public enum KinEcosystemError: LocalizedError {
    
    case client(KinClientErrorCode, Error?)
    case service(KinServiceErrorCode, Error?)
    case blockchain(KinBlockchainErrorCode, Error?)
    case unknown(KinUnknownErrorCode, Error?)
    
    public var errorDescription: String? {
        
        var description: String
        var underlyingError: Error? = nil
        
        switch self {
        case let KinEcosystemError.client(errorCode, error):
            underlyingError = error
            switch errorCode {
            case .notStarted:
                description = "Operation not permitted: Ecosystem SDK is not started"
            case .badRequest:
                description = "Bad or missing parameters"
            case .internalInconsistency:
                description = "Ecosystem SDK encountered an unexpected error"
            }
        case let KinEcosystemError.service(errorCode, error):
            underlyingError = error
            switch errorCode {
            case .response:
                description = "The Ecosystem server returned an error. See underlyingError for details"
            case .network:
                description = "Network unavailable. Please check that internet is accessible"
            case .timeout:
                description = "The operation timed out"
            }
        case let KinEcosystemError.blockchain(errorCode, error):
            underlyingError = error
            switch errorCode {
            case .creation:
                description = "Failed to create a blockchain wallet keypair"
            case .notFound:
                description = "The requested account could not be found"
            case .activation:
                description = "A Wallet was created locally, but wasn’t activated on the blockchain network"
            case .insufficientFunds:
                description = "You do not have enough Kin to perform this operation"
            case .txFailed:
                description = "The transaction operation failed. This can happen for several reasons. Please see underlyingError for more info"
            }
        default:
            description = "An unknown error has occurred"
        }
        
        if let uErr = underlyingError {
            description += "\nUnderlying error: \(uErr.localizedDescription)"
        }
        
        return description
    }
    
    public static func transform(_ rawError: Error) -> Error {
        if rawError is ResponseError {
            return KinEcosystemError.service(.response, rawError)
        } else if case KinError.insufficientFunds = rawError {
            return KinEcosystemError.blockchain(.insufficientFunds, rawError)
        } else if case let EcosystemNetError.service(responseError) = rawError {
            return KinEcosystemError.service(.response, responseError)
        } else if case let EcosystemNetError.network(networkError) = rawError {
            return KinEcosystemError.service(.network, networkError)
        } else {
            return KinEcosystemError.unknown(.unknown, rawError)
        }
    }
}



