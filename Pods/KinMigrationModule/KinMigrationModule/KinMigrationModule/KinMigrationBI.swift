//
//  KinMigrationBI.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 15/01/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

public enum KinMigrationBIBurnReason {
    case noAccount
    case noTrustline
    case burned
    case alreadyBurned
}

public enum KinMigrationBIMigrateReason {
    case noAccount
    case migrated
    case alreadyMigrated
}

public enum KinMigrationBIReadyReason {
    case noAccountToMigrate
    case apiCheck
    case migrated
    case alreadyMigrated
}

public protocol KinMigrationBIDelegate: NSObjectProtocol {
    func kinMigrationMethodStarted()

    func kinMigrationCallbackStart()
    func kinMigrationCallbackReady(reason: KinMigrationBIReadyReason, version: KinVersion)
    func kinMigrationCallbackFailed(error: Error)

    func kinMigrationVersionCheckStarted()
    func kinMigrationVersionCheckSucceeded(version: KinVersion)
    func kinMigrationVersionCheckFailed(error: Error)

    func kinMigrationBurnStarted(publicAddress: String)
    func kinMigrationBurnSucceeded(reason: KinMigrationBIBurnReason, publicAddress: String)
    func kinMigrationBurnFailed(error: Error, publicAddress: String)

    func kinMigrationRequestAccountMigrationStarted(publicAddress: String)
    func kinMigrationRequestAccountMigrationSucceeded(reason: KinMigrationBIMigrateReason, publicAddress: String)
    func kinMigrationRequestAccountMigrationFailed(error: Error, publicAddress: String)
}
