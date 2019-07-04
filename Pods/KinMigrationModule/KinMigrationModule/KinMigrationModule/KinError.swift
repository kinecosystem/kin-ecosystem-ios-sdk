//
//  KinError.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 19/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinSDK
import KinCoreSDK
import StellarErrors

public enum KinError: Error {
    // Kin Errors
    case accountCreationFailed (Error)
    case accountDeletionFailed (Error)
    case transactionCreationFailed (Error) // KinSDK Only
    case activationFailed (Error)          // KinCore Only
    case paymentFailed (Error)
    case balanceQueryFailed (Error)
    case invalidAppId                      // KinSDK Only
    case invalidAmount
    case insufficientFunds
    case accountDeleted
    case signingFailed
    case internalInconsistency
    case unknown

    // Stellar Errors
    case memoTooLong (Any?)
    case missingAccount
    case missingPublicKey
    case missingHash
    case missingSequence
    case missingBalance
    case missingSignClosure
    case urlEncodingFailed
    case dataEncodingFailed
    case dataDencodingFailed
    case destinationNotReadyForAsset (Error)
    case unknownError (Any?)

    // Other Errors
    case wrappedError (Error)
}

extension KinError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .accountCreationFailed:
            return "Account creation failed"
        case .accountDeletionFailed:
            return "Account deletion failed"
        case .transactionCreationFailed:
            return "Transaction creation failed"
        case .activationFailed:
            return "Account activation failed"
        case .paymentFailed:
            return "Payment failed"
        case .balanceQueryFailed:
            return "Balance query failed"
        case .invalidAppId:
            return "Invalid app id"
        case .invalidAmount:
            return "Invalid Amount"
        case .insufficientFunds:
            return "Insufficient funds"
        case .accountDeleted:
            return "Account Deleted"
        case .signingFailed:
            return "Signing Failed"
        case .internalInconsistency:
            return "Internal Inconsistency"
        case .unknown:
            return "Unknown Error"

        case .memoTooLong:
            return "Memo Too Long"
        case .missingAccount:
            return "Missing Account"
        case .missingPublicKey:
            return "Missing Public Key"
        case .missingHash:
            return "Missing Hash"
        case .missingSequence:
            return "Missing Sequence"
        case .missingBalance:
            return "Missing Balance"
        case .missingSignClosure:
            return "Missing Sign Closure"
        case .urlEncodingFailed:
            return "URL Encoding Failed"
        case .dataEncodingFailed:
            return "Data Encoding Failed"
        case .dataDencodingFailed:
            return "Data Dencoding Failed"
        case .destinationNotReadyForAsset:
            return "Destination Not Ready For Asset"
        case .unknownError:
            return "Unknown Error"

        case .wrappedError:
            return "Wrapped Error"
        }
    }
}

extension KinError {
    public init(error: Error) {
        self = KinError.mapError(error) ?? .wrappedError(error)
    }

    private static func mapError(_ error: Error) -> KinError? {
        if let error = error as? StellarErrors.StellarError {
            return stellarError(error)
        }
        else if let error = error as? KinSDK.StellarError {
            return stellarError(error)
        }
        else if let error = error as? KinCoreSDK.KinError {
            return kinError(error)
        }
        else if let error = error as? KinSDK.KinError {
            return kinError(error)
        }
        else {
            return nil
        }
    }

    private static func kinError(_ error: KinCoreSDK.KinError) -> KinError {
        switch error {
        case .accountCreationFailed (let e):
            return KinError.mapError(e) ?? .accountCreationFailed(e)
        case .accountDeletionFailed (let e):
            return KinError.mapError(e) ?? .accountDeletionFailed(e)
        case .activationFailed (let e):
            return KinError.mapError(e) ?? .activationFailed(e)
        case .paymentFailed (let e):
            return KinError.mapError(e) ?? .paymentFailed(e)
        case .balanceQueryFailed (let e):
            return KinError.mapError(e) ?? .balanceQueryFailed(e)
        case .invalidAmount:
            return .invalidAmount
        case .insufficientFunds:
            return .insufficientFunds
        case .accountDeleted:
            return .accountDeleted
        case .signingFailed:
            return .signingFailed
        case .internalInconsistency:
            return .internalInconsistency
        case .unknown:
            return .unknown
        }
    }

    private static func kinError(_ error: KinSDK.KinError) -> KinError {
        switch error {
        case .accountCreationFailed (let e):
            return KinError.mapError(e) ?? .accountCreationFailed(e)
        case .accountDeletionFailed (let e):
            return KinError.mapError(e) ?? .accountDeletionFailed(e)
        case .transactionCreationFailed (let e):
            return KinError.mapError(e) ?? .transactionCreationFailed(e)
        case .paymentFailed (let e):
            return KinError.mapError(e) ?? .paymentFailed(e)
        case .balanceQueryFailed (let e):
            return KinError.mapError(e) ?? .balanceQueryFailed(e)
        case .invalidAppId:
            return .invalidAppId
        case .invalidAmount:
            return .invalidAmount
        case .insufficientFunds:
            return .insufficientFunds
        case .accountDeleted:
            return .accountDeleted
        case .signingFailed:
            return .signingFailed
        case .internalInconsistency:
            return .internalInconsistency
        case .unknown:
            return .unknown
        }
    }

    private static func stellarError(_ error: StellarErrors.StellarError) -> KinError {
        switch error {
        case .memoTooLong (let object):
            return .memoTooLong(object)
        case .missingAccount:
            return .missingAccount
        case .missingPublicKey:
            return .missingPublicKey
        case .missingHash:
            return .missingHash
        case .missingSequence:
            return .missingSequence
        case .missingBalance:
            return .missingBalance
        case .missingSignClosure:
            return .missingSignClosure
        case .urlEncodingFailed:
            return .urlEncodingFailed
        case .dataEncodingFailed:
            return .dataEncodingFailed
        case .signingFailed:
            return .signingFailed
        case .destinationNotReadyForAsset (let e, _):
            return KinError.mapError(e) ?? .destinationNotReadyForAsset(e)
        case .unknownError (let object):
            return .unknownError(object)
        case .internalInconsistency:
            return .internalInconsistency
        }
    }

    private static func stellarError(_ error: KinSDK.StellarError) -> KinError {
        switch error {
        case .memoTooLong (let object):
            return .memoTooLong(object)
        case .missingAccount:
            return .missingAccount
        case .missingPublicKey:
            return .missingPublicKey
        case .missingHash:
            return .missingHash
        case .missingSequence:
            return .missingSequence
        case .missingBalance:
            return .missingBalance
        case .missingSignClosure:
            return .missingSignClosure
        case .urlEncodingFailed:
            return .urlEncodingFailed
        case .dataEncodingFailed:
            return .dataEncodingFailed
        case .dataDencodingFailed:
            return .dataDencodingFailed
        case .signingFailed:
            return .signingFailed
        case .destinationNotReadyForAsset (let e):
            return KinError.mapError(e) ?? .destinationNotReadyForAsset(e)
        case .unknownError (let object):
            return .unknownError(object)
        case .internalInconsistency:
            return .internalInconsistency
        }
    }
}
