//
//  KinAccount.swift
//  KinCoreSDK
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit
import StellarErrors
import KinUtil

/**
 `KinAccount` represents an account which holds Kin. It allows checking balance and sending Kin to
 other accounts.
 */
public protocol KinAccount: class {
    /**
     The public address of this account. If the user wants to receive KIN by sending his address
     manually to someone, or if you want to display the public address, use this property.
     */
    var publicAddress: String { get }

    var extra: Data? { get set }

    /**
     Export the account data as a JSON string.  The seed is encrypted.

     - parameter passphrase: The passphrase with which to encrypt the seed

     - return: A JSON representation of the data as a string
     **/
    func export(passphrase: String) throws -> String

    /**
     Allow an account to receive KIN.

     - parameter completion: A block which receives the results of the activation
     */
    func activate(completion: @escaping (String?, Error?) -> Void)

    /**
     Allow an account to receive KIN.

     - return: A promise which is signalled with the resulting transaction hash.
     */
    func activate() -> Promise<String>

    func status(completion: @escaping (AccountStatus?, Error?) -> Void)

    func status() -> Promise<AccountStatus>

    /**
     Burn the account.

     - Returns: A transaction hash if burned. If the burn already took place, `nil` will be returned.
     */
    func burn() -> Promise<String?>

    /**
     Posts a Kin transfer to a specific address.
     
     The completion block is called after the transaction is posted on the network, which is prior
     to confirmation.
     
     The completion block **is not dispatched on the main thread**.
     
     - parameter recipient: The recipient's public address
     - parameter kin: The amount of Kin to be sent
     - parameter memo: An optional string, up-to 28 bytes in length, included on the transaction record.
     */
    func sendTransaction(to recipient: String,
                         kin: Decimal,
                         memo: String?,
                         completion: @escaping TransactionCompletion)


    /**
     Posts a Kin transfer to a specific address.

     - parameter recipient: The recipient's public address
     - parameter kin: The amount of Kin to be sent
     - parameter memo: An optional string, up-to 28 bytes in length, included on the transaction record.

     - returns: A promise which is signalled with the `TransactionId`.
     */
    func sendTransaction(to recipient: String,
                         kin: Decimal,
                         memo: String?) -> Promise<TransactionId>

    /**
     Retrieve the current Kin balance.
     
     - parameter completion: A closure to be invoked once the request completes.  The closure is
     invoked on a background thread.
     */
    func balance(completion: @escaping BalanceCompletion)

    /**
     Retrieve the current Kin balance.

     - returns: A `Promise` which is signalled with the current balance.
     */
    func balance() -> Promise<Balance>

    func watchBalance(_ balance: Decimal?) throws -> BalanceWatch

    func watchPayments(cursor: String?) throws -> PaymentWatch

    func watchCreation() throws -> Promise<Void>

    /**
     Exports this account as a Key Store JSON string, to be backed up by the user.
     
     - parameter passphrase: The passphrase used to create the associated account.
     - parameter exportPassphrase: A new passphrase, to encrypt the Key Store JSON.
     
     - throws: If the passphrase is invalid, or if exporting the associated account fails.
     
     - returns: a prettified JSON string of the `account` exported; `nil` if `account` is `nil`.
     */
//    func exportKeyStore(passphrase: String, exportPassphrase: String) throws -> String?
}

let KinMultiplier: UInt64 = 10000000

final class KinStellarAccount: KinAccount {
    internal let stellarAccount: StellarAccount
    fileprivate let node: Stellar.Node
    fileprivate let asset: Asset

    var deleted = false
    
    var publicAddress: String {
        return stellarAccount.publicKey!
    }

    var extra: Data? {
        get {
            guard let extra = try? stellarAccount.extra() else {
                return nil
            }

            return extra
        }

        set {
            try? KeyStore.set(extra: newValue, for: stellarAccount)
        }
    }

    init(stellarAccount: StellarAccount, asset: Asset, node: Stellar.Node) {
        self.stellarAccount = stellarAccount
        self.asset = asset
        self.node = node
    }

    public func export(passphrase: String) throws -> String {
        let ad = KeyStore.exportAccount(account: stellarAccount,
                                        passphrase: "",
                                        newPassphrase: passphrase)

        guard let jsonString = try String(data: JSONEncoder().encode(ad), encoding: .utf8) else {
            throw KinError.internalInconsistency
        }

        return jsonString
    }

    public func activate(completion: @escaping (String?, Error?) -> Void) {
        stellarAccount.sign = { message in
            return try self.stellarAccount.sign(message: message, passphrase: "")
        }
        
        Stellar.trust(asset: asset,
                      account: stellarAccount,
                      node: node)
            .then { txHash -> Void in
                self.stellarAccount.sign = nil

                completion(txHash, nil)
            }
            .error { error in
                self.stellarAccount.sign = nil

                completion(nil, KinError.activationFailed(error))
        }
    }

    public func activate() -> Promise<String> {
        return promise(activate)
    }

    func status(completion: @escaping (AccountStatus?, Error?) -> Void) {
        balance { balance, error in
            if let error = error {
                if case let KinError.balanceQueryFailed(e) = error,
                    let stellarError = e as? StellarError {
                    switch stellarError {
                    case .missingAccount: completion(.notCreated, nil)
                    case .missingBalance: completion(.notActivated, nil)
                    default: completion(nil, error)
                    }
                }
                else {
                    completion(nil, error)
                }

                return
            }

            if balance != nil {
                completion(.activated, nil)
            }
            else {
                completion(nil, KinError.internalInconsistency)
            }
        }
    }

    func status() -> Promise<AccountStatus> {
        return promise(status)
    }

    func burn() -> Promise<String?> {
        let promise = Promise<String?>()

        balance()
            .then { balance -> Promise<String> in
                self.stellarAccount.sign = { message in
                    return try self.stellarAccount.sign(message: message, passphrase: "")
                }

                let intKin = ((balance * Decimal(KinMultiplier)) as NSDecimalNumber).int64Value

                return Stellar.burn(balance: intKin, asset: self.asset, account: self.stellarAccount, node: self.node)
            }
            .then { transactionHash in
                self.stellarAccount.sign = nil

                promise.signal(transactionHash)
            }
            .error { error in
                self.stellarAccount.sign = nil

                // Bad auth means the burn already happened.
                if case TransactionError.txBAD_AUTH = error {
                    promise.signal(nil)
                }
                else {
                    promise.signal(error)
                }
        }

        return promise
    }

    func sendTransaction(to recipient: String,
                         kin: Decimal,
                         memo: String? = nil,
                         completion: @escaping TransactionCompletion) {
        guard deleted == false else {
            completion(nil, KinError.accountDeleted)
            
            return
        }
        
        let intKin = ((kin * Decimal(KinMultiplier)) as NSDecimalNumber).int64Value
        
        guard intKin > 0 else {
            completion(nil, KinError.invalidAmount)
            
            return
        }

        stellarAccount.sign = { message in
            return try self.stellarAccount.sign(message: message, passphrase: "")
        }

        do {
            var m = Memo.MEMO_NONE
            if let memo = memo, !memo.isEmpty {
                m = try Memo(memo)
            }

            Stellar.payment(source: stellarAccount,
                            destination: recipient,
                            amount: intKin,
                            asset: asset,
                            memo: m,
                            node: node)
                .then { txHash -> Void in
                    self.stellarAccount.sign = nil

                    completion(txHash, nil)
                }
                .error { error in
                    self.stellarAccount.sign = nil

                    if let error = error as? PaymentError, error == .PAYMENT_UNDERFUNDED {
                        completion(nil, KinError.insufficientFunds)

                        return
                    }
                    
                    completion(nil, KinError.paymentFailed(error))
            }
        }
        catch {
            completion(nil, error)
        }
    }

    func sendTransaction(to recipient: String, kin: Decimal, memo: String?) -> Promise<TransactionId> {
        let txClosure = { (txComp: @escaping TransactionCompletion) in
            self.sendTransaction(to: recipient, kin: kin, memo: memo, completion: txComp)
        }

        return promise(txClosure)
    }

    func balance(completion: @escaping BalanceCompletion) {
        guard deleted == false else {
            completion(nil, KinError.accountDeleted)
            
            return
        }
        
        Stellar.balance(account: stellarAccount.publicKey!, asset: asset, node: node)
            .then { balance -> Void in
                completion(balance, nil)
            }
            .error { error in
                completion(nil, KinError.balanceQueryFailed(error))
        }
    }

    func balance() -> Promise<Balance> {
        return promise(balance)
    }
    
    public func watchBalance(_ balance: Decimal?) throws -> BalanceWatch {
        guard deleted == false else {
            throw KinError.accountDeleted
        }

        return BalanceWatch(node: node,
                            account: stellarAccount.publicKey!,
                            balance: balance,
                            asset: asset)
    }

    public func watchPayments(cursor: String?) throws -> PaymentWatch {
        guard deleted == false else {
            throw KinError.accountDeleted
        }

        return PaymentWatch(node: node,
                            account: stellarAccount.publicKey!,
                            asset: asset,
                            cursor: cursor)
    }

    public func watchCreation() throws -> Promise<Void> {
        guard deleted == false else {
            throw KinError.accountDeleted
        }

        let p = Promise<Void>()

        var linkBag = LinkBag()
        var watch: CreationWatch? = CreationWatch(node: node, account: stellarAccount.publicKey!)

        _ = watch?.emitter.on(next: { _ in
            watch = nil

            linkBag = LinkBag()
            
            p.signal(())
        })
            .add(to: linkBag)

        return p
    }

    @available(*, unavailable)
    private func exportKeyStore(passphrase: String, exportPassphrase: String) throws -> String? {
        let accountData = KeyStore.exportAccount(account: stellarAccount, passphrase: passphrase, newPassphrase: exportPassphrase)
        
        guard let store = accountData else {
            throw KinError.internalInconsistency
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: store,
                                                         options: [.prettyPrinted])
            else {
                return nil
        }
        
        return String(data: jsonData, encoding: .utf8)
    }
}
