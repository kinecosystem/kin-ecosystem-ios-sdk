//
//  KinClient.swift
//  KinCoreSDK
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit

/**
 `KinClient` is a factory class for managing an instance of `KinAccount`.
 */
public final class KinClient {
    /**
     Convenience initializer to instantiate a `KinClient` with a `ServiceProvider`.

     - parameter provider: The `ServiceProvider` instance that provides the `URL` and `NetworkId`.
     */
    public convenience init(provider: ServiceProvider) {
        self.init(with: provider.url, networkId: provider.networkId)
    }

    /**
     Instantiates a `KinClient` with a `URL` and a `NetworkId`.

     - parameter nodeProviderUrl: The `URL` of the node this client will communicate to.
     - parameter networkId: The `NetworkId` to be used.
     */
    public init(with nodeProviderUrl: URL, networkId: NetworkId) {
        KeyStore.migrateIfNeeded()
        
        self.node = Stellar.Node(baseURL: nodeProviderUrl,
                                 networkId: networkId.stellarNetworkId)

        self.asset = Asset(assetCode: "KIN", issuer: networkId.issuer)!

        self.accounts = KinAccounts(node: node, asset: asset)

        self.networkId = networkId
    }

    public var url: URL {
        return node.baseURL
    }

    public private(set) var accounts: KinAccounts

    internal let node: Stellar.Node
    internal let asset: Asset

    /**
     The `NetworkId` of the network which this client communicates to.
     */
    public let networkId: NetworkId

    /**
     Adds an account associated to this client, and returns it.

     - throws: If creating the account fails.
     */
    public func addAccount() throws -> KinAccount {
        do {
            return try accounts.createAccount()
        }
        catch {
            throw KinError.accountCreationFailed(error)
        }
    }

    /**
     Deletes the account at the given index. This method is a no-op if there is no account at
     that index.

     If this is an action triggered by the user, make sure you let the him know that any funds owned
     by the account will be lost if it hasn't been backed up. See
     `exportKeyStore(passphrase:exportPassphrase:)`.

     - parameter index: The index of the account to delete.

     - throws: When deleting the account fails.
     */
    public func deleteAccount(at index: Int) throws {
        do {
            try accounts.deleteAccount(at: index)
        }
        catch {
            throw KinError.accountDeletionFailed(error)
        }
    }

    /**
     Import an account from a JSON-formatted string.

     - parameter passphrase: The passphrase to decrypt the secret key.

     - return: The imported account
     **/
    public func importAccount(_ jsonString: String,
                              passphrase: String) throws -> KinAccount {
        guard let data = jsonString.data(using: .utf8) else {
            throw KinError.internalInconsistency
        }

        let accountData = try JSONDecoder().decode(AccountData.self, from: data)

        try KeyStore.importAccount(accountData,
                                   passphrase: passphrase,
                                   newPassphrase: "")

        guard let account = accounts.last else {
            throw KinError.internalInconsistency
        }

        return account
    }

    /**
     Deletes the keystore.
     */
    public func deleteKeystore() {
        for _ in 0..<KeyStore.count() {
            KeyStore.remove(at: 0)
        }

        accounts.flushCache()
    }
}
