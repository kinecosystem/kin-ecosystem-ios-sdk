//
//  WrappedKinCoreClient.swift
//  multi
//
//  Created by Corey Werner on 04/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinCoreSDK
import KinUtil
import StellarKit

class WrappedKinCoreClient: KinClientProtocol {
    let client: KinCoreSDK.KinClient

    private(set) var url: URL
    private(set) var network: Network

    required init(with url: URL, network: Network, appId: AppId) {
        self.url = url
        self.network = network
        self.client = KinCoreSDK.KinClient(with: url, networkId: network.mapToKinCore)
        self.wrappedAccounts = WrappedKinCoreAccounts(client.accounts, appId: appId)
    }

    // MARK: Account

    private let wrappedAccounts: WrappedKinCoreAccounts

    var accounts: KinAccountsProtocol {
        return wrappedAccounts
    }

    func addAccount() throws -> KinAccountProtocol {
        do {
            return wrappedAccounts.addWrappedAccount(try client.addAccount())
        }
        catch {
            throw KinError(error: error)
        }
    }

    func deleteAccount(at index: Int) throws {
        if let account = client.accounts[index] {
            wrappedAccounts.deleteWrappedAccount(account)
        }

        do {
            try client.deleteAccount(at: index)
        }
        catch {
            throw KinError(error: error)
        }
    }

    func importAccount(_ jsonString: String, passphrase: String) throws -> KinAccountProtocol {
        do {
            let account = try client.importAccount(jsonString, passphrase: passphrase)
            return wrappedAccounts.addWrappedAccount(account)
        }
        catch {
            throw KinError(error: error)
        }
    }

    // MARK: Keystore

    func deleteKeystore() {
        client.deleteKeystore()
    }

    // MARK: Fee

    func minFee() -> Promise<Stroop> {
        return Promise(0)
    }
}
