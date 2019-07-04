//
//  WrappedKinSDKAccount.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinSDK

class WrappedKinSDKAccount: KinAccountProtocol {
    let account: KinSDK.KinAccount

    var publicAddress: String {
        return account.publicAddress
    }

    var extra: Data? {
        get {
            return account.extra
        }
        set {
            account.extra = newValue
        }
    }

    init(_ kinAccount: KinSDK.KinAccount) {
        self.account = kinAccount
    }

    func activate() -> Promise<Void> {
        return Promise(Void())
    }

    func status() -> Promise<AccountStatus> {
        let promise = Promise<AccountStatus>()

        account.status()
            .then { accountStatus in
                promise.signal(accountStatus.mapToKinMigration)
            }
            .error { error in
                promise.signal(KinError(error: error))
        }

        return promise
    }

    func balance() -> Promise<Kin> {
        let promise = Promise<Kin>()

        account.balance()
            .then { kin in
                promise.signal(kin)
            }
            .error { error in
                promise.signal(KinError(error: error))
        }

        return promise
    }

    func burn() -> Promise<String?> {
        return Promise(nil)
    }

    // MARK: Transaction

    func sendTransaction(to recipient: String, kin: Kin, memo: String?, fee: Stroop, whitelist: @escaping WhitelistClosure) -> Promise<TransactionId> {
        let promise = Promise<TransactionId>()

        account.generateTransaction(to: recipient, kin: kin, memo: memo, fee: fee)
            .then { transactionEnvelope -> Promise<TransactionEnvelope?> in
                return whitelist(transactionEnvelope)
            }
            .then { [weak self] transactionEnvelope -> Promise<TransactionId> in
                guard let transactionEnvelope = transactionEnvelope else {
                    return promise.signal("")
                }

                guard let strongSelf = self else {
                    return promise.signal(KinError.internalInconsistency)
                }

                return strongSelf.account.sendTransaction(transactionEnvelope)
            }
            .then { transactionId -> Void in
                promise.signal(transactionId)
            }
            .error { error in
                promise.signal(KinError(error: error))
        }

        return promise
    }

    // MARK: Export

    func export(passphrase: String) throws -> String {
        do {
            return try account.export(passphrase: passphrase)
        }
        catch {
            throw KinError(error: error)
        }
    }

    // MARK: Watchers

    func watchCreation() throws -> Promise<Void> {
        do {
            let promise = Promise<Void>()

            try account.watchCreation()
                .then { _ in
                    promise.signal(Void())
                }
                .error { error in
                    promise.signal(KinError(error: error))
            }

            return promise
        }
        catch {
            throw KinError(error: error)
        }
    }

    func watchBalance(_ balance: Kin?) throws -> BalanceWatchProtocol {
        do {
            return WrappedKinSDKBalanceWatch(try account.watchBalance(balance))
        }
        catch {
            throw KinError(error: error)
        }
    }

    func watchPayments(cursor: String?) throws -> PaymentWatchProtocol {
        do {
            return WrappedKinSDKPaymentWatch(try account.watchPayments(cursor: cursor))
        }
        catch {
            throw KinError(error: error)
        }
    }
}

extension KinSDK.AccountStatus {
    fileprivate var mapToKinMigration: AccountStatus {
        switch self {
        case .created:
            return .created
        case .notCreated:
            return .notCreated
        }
    }
}
