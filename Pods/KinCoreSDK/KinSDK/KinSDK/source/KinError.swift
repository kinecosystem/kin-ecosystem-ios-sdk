//
//  KinError.swift
//  KinCoreSDK
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import Foundation

/**
 Operations performed by the KinCoreSDK that throw errors might throw a `KinError`; alternatively,
 errors in completion blocks might be of this type.
 */
public enum KinError: Error {
    /**
     Account creation failed.
     */
    case accountCreationFailed (Error)

    /**
     Account deletion failed.
     */
    case accountDeletionFailed (Error)

    /**
     Account activation failed.
     */
    case activationFailed (Error)

    /**
     Sending a payment failed.
     */
    case paymentFailed (Error)

    /**
     Querying for the account balance failed.
     */
    case balanceQueryFailed (Error)

    /**
     Amounts must be greater than zero when trying to transfer Kin. When sending 0 Kin, this error
     is thrown.
     */
    case invalidAmount

    /**
     The account does not have sufficient Kin to complete the transaction.
     */
    case insufficientFunds

    /**
     Thrown when trying to use an instance of `KinAccount` after `deleteAccount(:)` has been called.
     */
    case accountDeleted

    /**
     Thrown when signing a transaction fails.
     */
    case signingFailed

    /**
     An internal error happened in the KinCoreSDK.
     */
    case internalInconsistency

    /**
     An unknown error happened.
     */
    case unknown
}

extension KinError: LocalizedError {
    /// :nodoc:
    public var errorDescription: String? {
        switch self {
        case .accountCreationFailed:
            return "Account creation failed"
        case .accountDeletionFailed:
            return "Account deletion failed"
        case .activationFailed:
            return "Account activation failed"
        case .paymentFailed:
            return "Payment failed"
        case .balanceQueryFailed:
            return "Balance query failed"
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
        }
    }
}
