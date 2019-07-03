//
//  KinMigrationManager.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinUtil

public protocol KinMigrationManagerDelegate: NSObjectProtocol {
    /**
     Asks the delegate for the Kin version to be used.

     The returned value is passed in a `Promise` allowing for the answer to be determined from a
     URL request. The migration process will only begin if `.kinSDK` is returned.

     - Parameter kinMigrationManager: The migration manager object requesting this information.

     - Returns: A `Promise` of the `KinVersion` to be used.
     */
    func kinMigrationManagerNeedsVersion(_ kinMigrationManager: KinMigrationManager) -> Promise<KinVersion>

    /**
     Tells the delegate that the migration process has begun.

     The migration process will only start if the version is `.kinSDK`.

     - Parameter kinMigrationManager: The migration manager object providing this information.
     */
    func kinMigrationManagerDidStart(_ kinMigrationManager: KinMigrationManager)

    /**
     Tells the delegate that the client is ready to be used.

     When the migration manager uses Kin Core, or when the accounts have successfully migrated
     to the Kin SDK, the client will be returned.

     - Parameter kinMigrationManager: The migration manager object providing this information.
     - Parameter client: The client used to interact with Kin.
     */
    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, readyWith client: KinClientProtocol)

    /**
     Tells the delegate that the migration encountered an error.

     When an error is encountered, the migration process will be stopped.

     - Parameter kinMigrationManager: The migration manager object providing this information.
     - Parameter error: The error which stopped the migration process.
     */
    func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, error: Error)
}

public class KinMigrationManager {
    public weak var delegate: KinMigrationManagerDelegate?

    /**
     Delegate for business intelligence events.
     */
    public weak var biDelegate: KinMigrationBIDelegate?

    /**
     The `KinVersion` being used by the migration manager.

     The version received from the `kinMigrationManagerNeedsVersion(_:)` delegate.
     */
    public fileprivate(set) var version: KinVersion?
    
    public let serviceProvider: ServiceProviderProtocol
    public let appId: AppId

    /**
     Initializes and returns a migration manager object having the given service provider and
     appId.

     - Parameter serviceProvider: The service provider for the migration manager.
     - Parameter appId: The `AppId` attached to all transactions.
     */
    public init(serviceProvider: ServiceProviderProtocol, appId: AppId) {
        self.serviceProvider = serviceProvider
        self.appId = appId
    }

    private var didStart = false
    private var migratePublicAddress: String?

    private lazy var kinCoreClient: KinClientProtocol = {
        return self.createClient(version: .kinCore)
    }()

    private lazy var kinSDKClient: KinClientProtocol = {
        return self.createClient(version: .kinSDK)
    }()

    /**
     Get a `KinClientProtocol` for a specific version.

     The version should be the same as your servers.

     - Parameter version: The `KinVersion` for which `KinClientProtocol` to receive.

     - Returns: A `KinClientProtocol` for the given `KinVersion`.
     */
    public func kinClient(version: KinVersion) -> KinClientProtocol {
        switch version {
        case .kinCore:
            return kinCoreClient
        case .kinSDK:
            return kinSDKClient
        }
    }

    /**
     Check if a `kinAccount` has been migrated.

     - Parameter publicAddress: The `kinAccount.publicAddress` to be checked.

     - Returns: True if the `kinAccount` with the given `publicAddress` has been migrated.
     */
    public func isAccountMigrated(publicAddress: String) -> Bool {
        return kinSDKClient.accounts.makeIterator().first { $0.publicAddress == publicAddress } != nil
    }
}

// MARK: - State

extension KinMigrationManager {
    /**
     Tell the migration manager to start the migration process.

     If the `publicAddress` is omitted the migration manager will still request a version and
     call the `readyWithClient` delegate function, returning the correct client.

     - Parameter publicAddress: The `kinAccount.publicAddress` to be migrated.

     - Throws: An error if the `delegate` was not set.
     */
    public func start(with publicAddress: String? = nil) throws {
        guard !didStart else {
            return
        }

        guard delegate != nil else {
            throw KinMigrationError.missingDelegate
        }

        migratePublicAddress = publicAddress
        didStart = true

        biDelegate?.kinMigrationMethodStarted()

        if let publicAddress = publicAddress, isAccountMigrated(publicAddress: publicAddress) {
            version = .kinSDK
            completed(biReadyReason: .alreadyMigrated)
        }
        else {
            requestVersion()
        }
    }

    fileprivate func startMigration() {
        guard kinCoreClient.accounts.count > 0 else {
            completed(biReadyReason: .noAccountToMigrate)
            return
        }

        guard let account = kinCoreClient.accounts.makeIterator().first(where: { $0.publicAddress == migratePublicAddress }) else {
            failed(error: KinMigrationError.invalidPublicAddress)
            return
        }

        biDelegate?.kinMigrationCallbackStart()
        delegate?.kinMigrationManagerDidStart(self)

        startBurningAccount(account)
    }

    fileprivate func completed(biReadyReason: KinMigrationBIReadyReason) {
        didStart = false
        migratePublicAddress = nil

        guard let version = version else {
            failed(error: KinMigrationError.unexpectedCondition)
            return
        }

        biDelegate?.kinMigrationCallbackReady(reason: biReadyReason, version: version)

        let client: KinClientProtocol

        switch version {
        case .kinCore:
            client = kinCoreClient
        case .kinSDK:
            client = kinSDKClient
        }

        delegate?.kinMigrationManager(self, readyWith: client)
    }

    fileprivate func failed(error: Error) {
        didStart = false
        migratePublicAddress = nil

        biDelegate?.kinMigrationCallbackFailed(error: error)
        delegate?.kinMigrationManager(self, error: error)
    }
}

// MARK: - Version

extension KinMigrationManager {
    fileprivate func requestVersion() {
        biDelegate?.kinMigrationVersionCheckStarted()

        delegate?.kinMigrationManagerNeedsVersion(self)
            .then { version in
                DispatchQueue.main.async {
                    self.biDelegate?.kinMigrationVersionCheckSucceeded(version: version)

                    self.version = version

                    switch version {
                    case .kinCore:
                        self.completed(biReadyReason: .apiCheck)
                    case .kinSDK:
                        self.startMigration()
                    }
                }
            }
            .error { error in
                DispatchQueue.main.async {
                    self.biDelegate?.kinMigrationVersionCheckFailed(error: error)
                    self.failed(error: error)
                }
        }
    }
}

// MARK: - Client

extension KinMigrationManager {
    fileprivate func createClient(version: KinVersion) -> KinClientProtocol {
        let factory = KinClientFactory(version: version)
        return factory.KinClient(serviceProvider: serviceProvider, appId: appId)
    }
}

// MARK: - Account

extension KinMigrationManager {
    fileprivate func startBurningAccount(_ account: KinAccountProtocol) {
        guard version == .kinSDK else {
            failed(error: KinMigrationError.unexpectedCondition)
            return
        }

        DispatchQueue.global(qos: .background).async {
            self.burnAccount(account)
                .then { account in
                    DispatchQueue.main.async {
                        self.startMigratingAccount(account)
                    }
                }
                .error { error in
                    DispatchQueue.main.async {
                        self.failed(error: error)
                    }
            }
        }
    }

    private func burnAccount(_ account: KinAccountProtocol) -> Promise<KinAccountProtocol> {
        biDelegate?.kinMigrationBurnStarted(publicAddress: account.publicAddress)

        let promise = Promise<KinAccountProtocol>()

        account.burn()
            .then { transactionHash in
                let didMigrate = transactionHash != nil

                let reason: KinMigrationBIBurnReason = didMigrate ? .burned : .alreadyBurned
                self.biDelegate?.kinMigrationBurnSucceeded(reason: reason, publicAddress: account.publicAddress)

                promise.signal(account)
            }
            .error { error in
                func success(reason: KinMigrationBIBurnReason) {
                    self.biDelegate?.kinMigrationBurnSucceeded(reason: reason, publicAddress: account.publicAddress)

                    promise.signal(account)
                }

                switch error {
                case KinError.missingAccount:
                    success(reason: .noAccount)
                case KinError.missingBalance:
                    success(reason: .noTrustline)
                default:
                    self.biDelegate?.kinMigrationBurnFailed(error: error, publicAddress: account.publicAddress)

                    promise.signal(error)
                }
        }

        return promise
    }

    private func startMigratingAccount(_ account: KinAccountProtocol) {
        guard version == .kinSDK else {
            failed(error: KinMigrationError.unexpectedCondition)
            return
        }

        DispatchQueue.global(qos: .background).async {
            self.migrateAccount(account)
                .then { _ in
                    DispatchQueue.main.async {
                        self.completed(biReadyReason: .migrated)
                    }
                }
                .error { error in
                    DispatchQueue.main.async {
                        self.failed(error: error)
                    }
            }
        }
    }

    private func migrateAccount(_ account: KinAccountProtocol) -> Promise<Void> {
        let url: URL

        do {
            url = try serviceProvider.migrateURL(publicAddress: account.publicAddress)
        }
        catch {
            return Promise(error)
        }

        biDelegate?.kinMigrationRequestAccountMigrationStarted(publicAddress: account.publicAddress)

        let promise = Promise<Void>()

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        KinRequest(urlRequest).resume()
            .then { response in
                func success(reason: KinMigrationBIMigrateReason) {
                    self.biDelegate?.kinMigrationRequestAccountMigrationSucceeded(reason: reason, publicAddress: account.publicAddress)

                    do {
                        try self.moveAccountToKinSDKIfNeeded(account)
                        promise.signal(Void())
                    }
                    catch {
                        promise.signal(error)
                    }
                }

                switch response.code {
                case KinRequest.MigrateCode.success.rawValue:
                    success(reason: .migrated)
                case KinRequest.MigrateCode.accountAlreadyMigrated.rawValue:
                    success(reason: .alreadyMigrated)
                case KinRequest.MigrateCode.accountNotFound.rawValue:
                    success(reason: .noAccount)
                default:
                    let error = KinMigrationError.migrationFailed(code: response.code, message: response.message)

                    self.biDelegate?.kinMigrationRequestAccountMigrationFailed(error: error, publicAddress: account.publicAddress)

                    promise.signal(error)
                }
            }
            .error { error in
                self.biDelegate?.kinMigrationRequestAccountMigrationFailed(error: error, publicAddress: account.publicAddress)

                promise.signal(error)
            }

        return promise
    }

    /**
     Move the Kin Core keychain account to the Kin SDK keychain.
     */
    private func moveAccountToKinSDKIfNeeded(_ account: KinAccountProtocol) throws {
        let hasAccount = kinSDKClient.accounts.makeIterator().contains { kinSDKAccount -> Bool in
            return kinSDKAccount.publicAddress == account.publicAddress
        }

        guard hasAccount == false else {
            return
        }

        let json = try account.export(passphrase: "")
        var importedAccount = try kinSDKClient.importAccount(json, passphrase: "")
        importedAccount.extra = account.extra
    }
}

// MARK: Keystore

extension KinMigrationManager {
    public func deleteKeystore() {
        kinCoreClient.deleteKeystore()
        kinSDKClient.deleteKeystore()
    }
}
