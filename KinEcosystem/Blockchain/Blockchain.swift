//
//  Blockchain.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 11/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import KinCoreSDK
import StellarKit
import StellarErrors

struct BlockchainProvider: ServiceProvider {
    let url: URL
    let networkId: KinCoreSDK.NetworkId
}

struct PaymentMemoIdentifier: CustomStringConvertible, Equatable, Hashable {
    var hashValue: Int {
        return description.hashValue
    }

    let version = "1"
    var appId: String
    var id: String

    var description: String {
        return "\(version)-\(appId)-\(id)"
    }

    static func ==(lhs: PaymentMemoIdentifier, rhs: PaymentMemoIdentifier) -> Bool {
        return lhs.description == rhs.description
    }
}

enum BlockchainError: Error {
    case watchNotStarted
    case watchTimedOut
}

@available(iOS 9.0, *)
class Blockchain {

    let client: KinClient
    fileprivate(set) var account: KinAccount!
    private let linkBag = LinkBag()
    private var paymentObservers = [PaymentMemoIdentifier : Observable<String>]()
    private var balanceObservers = [String : (Balance) -> ()]()
    private var paymentsWatcher: KinCoreSDK.PaymentWatch?
    private var balanceWatcher: KinCoreSDK.BalanceWatch?
    let onboardEvent = Observable<Bool>()
    fileprivate(set) var balanceObservable = Observable<Balance>()
    fileprivate(set) var lastBalance: Balance? {
        get {
            if  let data = UserDefaults.standard.data(forKey: KinPreferenceKey.lastBalance.rawValue),
                let cachedBalance = try? JSONDecoder().decode(Balance.self, from: data) {
                    return cachedBalance
            }
            return nil
        }
        set {
            let oldValue = lastBalance
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: KinPreferenceKey.lastBalance.rawValue)
            }
            if let balance = newValue {
                balanceObservable.next(balance)
            } else {
                UserDefaults.standard.set(nil, forKey: KinPreferenceKey.lastBalance.rawValue)
            }
            if newValue != oldValue {
                updateBalanceObservers()
            }
        }


    }
    fileprivate(set) var onboarded: Bool {
        get {
            return account.extra != nil
        }
        set {
            guard newValue else {
                account.extra = nil
                return
            }
            onboardEvent.next(true)
            onboardEvent.finish()
            account.extra = Data()
        }
    }

    init(environment: Environment, appId: String) throws {
        guard let bURL = URL(string: environment.blockchainURL) else {
            throw KinEcosystemError.client(.badRequest, nil)
        }
        let provider = BlockchainProvider(url: bURL, networkId: .custom(issuer: environment.kinIssuer, stellarNetworkId: .custom(environment.blockchainPassphrase)))
        let client = try KinClient(provider: provider, appId: AppId(appId))
        self.client = client
    }

    func startAccount() throws {
        if Kin.shared.needsReset {
            lastBalance = nil
            try? client.deleteAccount(at: 0)
        }
        if let acc = client.accounts[0] {
            account = acc
        } else {
            Kin.track { try StellarAccountCreationRequested() }
            account = try client.addAccount()
        }
        _ = balance()
    }
    
    func balance() -> Promise<Decimal> {
        let p = Promise<Decimal>()
        account.balance(completion: { [weak self] balance, error in
            if let error = error {
                p.signal(error)
            } else if let balance = balance {
                self?.lastBalance = Balance(amount: balance)
                p.signal(balance)
            } else {
                p.signal(KinError.internalInconsistency)
            }
        })

        return p
    }

    func onboard() -> Promise<Void> {
        let p = Promise<Void>()

        if onboarded {
            return p.signal(())
        }

        balance()
            .then { _ in
                self.onboarded = true
                p.signal(())
            }
            .error { (bError) in
                if case let KinError.balanceQueryFailed(error) = bError {
                    if let error = error as? StellarError {
                        switch error {
                        case .missingAccount:
                            do {
                                try self.account.watchCreation().then {
                                    self.account.activate()
                                }.then { _ in
                                    Kin.track { try StellarKinTrustlineSetupSucceeded() }
                                    Kin.track { try WalletCreationSucceeded() }
                                    self.onboarded = true
                                    p.signal(())
                                }.error { error in
                                    Kin.track { try StellarKinTrustlineSetupFailed(errorReason: error.localizedDescription) }
                                    p.signal(error)
                                }
                            } catch {
                                p.signal(error)
                            }
                        case .missingBalance:
                            self.account.activate().then { _ in
                                Kin.track { try StellarKinTrustlineSetupSucceeded() }
                                Kin.track { try WalletCreationSucceeded() }
                                self.onboarded = true
                                p.signal(())
                            }.error { error in
                                Kin.track { try StellarKinTrustlineSetupFailed(errorReason: error.localizedDescription) }
                                p.signal(error)
                            }
                        default:
                            p.signal(KinError.unknown)
                        }
                    }
                    else {
                        p.signal(bError)
                    }
                }
                else {
                    p.signal(bError)
                }
        }

        return p
    }


    func pay(to recipient: String, kin: Decimal, memo: String?) -> Promise<TransactionId> {
        return account.sendTransaction(to: recipient, kin: kin, memo: memo)
    }

    func startWatchingForNewPayments(with memo: PaymentMemoIdentifier) throws {
        guard paymentsWatcher == nil else {
            logInfo("payment watcher already started, added watch for \(memo)...")
            paymentObservers[memo] = Observable<String>()
            return
        }
        paymentsWatcher = try account.watchPayments(cursor: "now")
        paymentsWatcher?.emitter.on(next: { [weak self] paymentInfo in
            guard let metadata = paymentInfo.memoText else { return }
            guard let match = self?.paymentObservers.first(where: { (memoKey, _) -> Bool in
                memoKey.description == metadata
            })?.value else { return }
            logInfo("payment found in blockchain for \(metadata)...")
            match.next(paymentInfo.hash)
            match.finish()
        }).add(to: linkBag)
        logInfo("added watch for \(memo)...")
        paymentObservers[memo] = Observable<String>()
    }

    func stopWatchingForNewPayments(with memo: PaymentMemoIdentifier? = nil) {
        guard let memo = memo else {
            paymentObservers.removeAll()
            paymentsWatcher = nil
            logInfo("removed all payment observers")
            return
        }
        paymentObservers.removeValue(forKey: memo)
        if paymentObservers.count == 0 {
            paymentsWatcher = nil
        }
        logInfo("removed payment observer for \(memo)")
    }

    func waitForNewPayment(with memo: PaymentMemoIdentifier, timeout: TimeInterval = 300.0) -> Promise<String> {
        let p = Promise<String>()
        guard paymentObservers.keys.contains(where: { key -> Bool in
            key == memo
        }) else {
            return p.signal(BlockchainError.watchNotStarted)
        }
        var found = false
        paymentObservers[memo]?.on(next: { [weak self] txHash in
            found = true
            _ = self?.balance()
            p.signal(txHash)
        }).add(to: linkBag)
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            if !found {
                p.signal(BlockchainError.watchTimedOut)
            }
        }
        return p
    }

    private func updateBalanceObservers() {
        guard let balance = lastBalance else { return }
        balanceObservers.values.forEach { block in
            block(balance)
        }
    }

    func addBalanceObserver(with block:@escaping (Balance) -> (), identifier: String? = nil) throws -> String {

        let observerIdentifier = identifier ?? UUID().uuidString
        balanceObservers[observerIdentifier] = block

        if balanceWatcher == nil {
            balanceWatcher = try account.watchBalance(lastBalance?.amount)
            balanceWatcher?.emitter.on(next: { [weak self] amount in
                self?.lastBalance = Balance(amount: amount)
            }).add(to: linkBag)
        }
        if let balance = lastBalance {
            block(balance)
        }

        return observerIdentifier
    }

    func removeBalanceObserver(with identifier: String) {
        balanceObservers[identifier] = nil
        if balanceObservers.count == 0 {
            balanceWatcher?.emitter.unlink()
            balanceWatcher = nil
        }
    }
}
