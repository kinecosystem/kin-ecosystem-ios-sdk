//
//  WrappedKinSDKClient.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinSDK

class WrappedKinSDKClient: KinClientProtocol {
    let client: KinSDK.KinClient

    private(set) var url: URL
    private(set) var network: Network

    required init(with url: URL, network: Network, appId: AppId) {
        self.url = url
        self.network = network
        self.client = KinSDK.KinClient(with: url, network: network.mapToKinSDK, appId: appId)
        self.wrappedAccounts = WrappedKinSDKAccounts(client.accounts)
    }

    // MARK: Account

    private let wrappedAccounts: WrappedKinSDKAccounts

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
        let promise = Promise<Stroop>()

        client.minFee()
            .then { stroop in
                promise.signal(stroop)
            }
            .error { error in
                promise.signal(KinError(error: error))
        }

        return promise
    }
}
