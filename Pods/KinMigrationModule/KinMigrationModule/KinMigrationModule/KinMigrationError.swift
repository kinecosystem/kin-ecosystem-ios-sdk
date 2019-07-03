//
//  KinMigrationError.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 02/01/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

public enum KinMigrationError: Error {
    case invalidNetwork
    case invalidMigrationURL
    case missingDelegate
    case responseEmpty
    case responseFailed (Error)
    case decodingFailed (Error)
    case invalidPublicAddress
    case migrationFailed (code: Int, message: String)
    case migrationNeeded
    case unexpectedCondition
}

extension KinMigrationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidNetwork:
            return "The provided `network` is invalid."
        case .invalidMigrationURL:
            return "The provided `migrateBaseURL` is invalid."
        case .missingDelegate:
            return "The `delegate` was not set."
        case .responseEmpty:
            return "Response was empty."
        case .responseFailed:
            return "Response failed."
        case .decodingFailed:
            return "Decoding response failed."
        case .invalidPublicAddress:
            return "The public address doesn't match any `kinClient.accounts`."
        case .migrationFailed:
            return "Migrating account failed."
        case .migrationNeeded:
            return "The user wallet has been migrated to the Kin blockchain. No Kin transactions will succeed until the client is migrated too."
        case .unexpectedCondition:
            return "An unexpected condition was met."
        }
    }
}
