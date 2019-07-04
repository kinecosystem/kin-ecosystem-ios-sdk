//
//  WrappedKinSDKAccounts.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinSDK

class WrappedKinSDKAccounts: KinAccountsProtocol {
    let accounts: KinSDK.KinAccounts

    var count: Int {
        return accounts.count
    }

    var first: KinAccountProtocol? {
        return wrappedAccount(accounts.first)
    }

    var last: KinAccountProtocol? {
        return wrappedAccount(accounts.last)
    }

    init(_ kinAccounts: KinSDK.KinAccounts) {
        self.accounts = kinAccounts
        restoreWrappedAccount()
    }

    subscript(index: Int) -> KinAccountProtocol? {
        return wrappedAccount(accounts[index])
    }

    // MARK: Wrapped Accounts

    private var wrappedAccounts: [WrappedKinSDKAccount] = []

    func wrappedAccount(_ account: KinSDK.KinAccount?) -> WrappedKinSDKAccount? {
        if let account = account {
            return wrappedAccounts.first { $0.account.publicAddress == account.publicAddress }
        }
        return nil
    }

    func wrappedAccountIndex(_ account: KinSDK.KinAccount?) -> Int? {
        if let account = account {
            return wrappedAccounts.firstIndex { $0.account.publicAddress == account.publicAddress }
        }
        return nil
    }

    @discardableResult
    func addWrappedAccount(_ account: KinSDK.KinAccount) -> WrappedKinSDKAccount {
        let wrappedAccount = WrappedKinSDKAccount(account)
        wrappedAccounts.append(wrappedAccount)
        return wrappedAccount
    }

    func deleteWrappedAccount(_ account: KinSDK.KinAccount) {
        if let index = wrappedAccountIndex(account) {
            wrappedAccounts.remove(at: index)
        }
    }

    private func restoreWrappedAccount() {
        for i in 0..<count {
            if let account = accounts[i] {
                addWrappedAccount(account)
            }
        }
    }

    // MARK: Random Access Collection

    var startIndex: Int {
        return accounts.startIndex
    }

    var endIndex: Int {
        return accounts.endIndex
    }

    // MARK: Sequence

    func makeIterator() -> AnyIterator<KinAccountProtocol> {
        return AnyIterator(stride(from: 0, to: self.count, by: 1).lazy.compactMap { self[$0] }.makeIterator())
    }
}
