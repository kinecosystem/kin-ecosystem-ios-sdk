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
    private let provider: BlockchainProvider
    private var creationWatch: StellarKit.PaymentWatch?
    private var creationLinkBag = LinkBag()
    private(set) var onboardInFlight = false
    private var isOnboarding: Bool {
        get {
            var result: Bool!
            synced(self) {
                result = onboardInFlight
            }
            return result
        }
        set {
            synced(self) {
                onboardInFlight = newValue
            }
        }
    }
    private var onboardPromise = Promise<Void>()
    private var onboardLock: Int = 1
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
            var result: Bool!
            synced(onboardLock) {
                result = account.extra != nil
            }
            return result
        }
        set {
            isOnboarding = false
            guard newValue else {
                synced(onboardLock) {
                    account.extra = nil
                }
                return
            }
            synced(onboardLock) {
                account.extra = Data()
            }
        }
    }

    init(environment: Environment, appId: String) throws {
        guard let bURL = URL(string: environment.blockchainURL) else {
            throw KinEcosystemError.client(.badRequest, nil)
        }
        provider = BlockchainProvider(url: bURL, networkId: .custom(issuer: environment.kinIssuer, stellarNetworkId: .custom(environment.blockchainPassphrase)))
        let client = KinClient(provider: provider)
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
       
        if onboarded {
            return Promise<Void>().signal(())
        }
        
        if isOnboarding {
            return onboardPromise
        }
        
        onboardPromise = Promise<Void>()
        isOnboarding = true
        
        balance()
            .then { _ in
                self.onboardPromise.signal(())
                self.onboarded = true
            }
            .error { (bError) in
                if case let KinError.balanceQueryFailed(error) = bError {
                    if let error = error as? StellarError {
                        switch error {
                        case .missingAccount:
                            self.watchAccountCreation(timeout: 15.0)
                                .then {
                                    self.account.activate()
                                }.then { _ in
                                    Kin.track { try StellarKinTrustlineSetupSucceeded() }
                                    Kin.track { try WalletCreationSucceeded() }
                                    self.onboardPromise.signal(())
                                    self.onboarded = true
                                }.error { error in
                                    Kin.track { try StellarKinTrustlineSetupFailed(errorReason: error.localizedDescription) }
                                    self.onboardPromise.signal(error)
                                    self.onboarded = false
                                }
                            
                        case .missingBalance:
                            self.account.activate().then { _ in
                                Kin.track { try StellarKinTrustlineSetupSucceeded() }
                                Kin.track { try WalletCreationSucceeded() }
                                self.onboardPromise.signal(())
                                self.onboarded = true
                            }.error { error in
                                Kin.track { try StellarKinTrustlineSetupFailed(errorReason: error.localizedDescription) }
                                self.onboardPromise.signal(error)
                                self.onboarded = false
                            }
                        default:
                            self.onboardPromise.signal(error)
                            self.onboarded = false
                        }
                    }
                    else {
                        self.onboardPromise.signal(bError)
                        self.onboarded = false
                    }
                }
                else {
                    self.onboardPromise.signal(bError)
                    self.onboarded = false
                }
        }

        return onboardPromise
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
    
    func watchAccountCreation(timeout: TimeInterval = 30.0) -> Promise<Void> {
        
        let p = Promise<Void>()
        let node = Stellar.Node(baseURL: provider.url, networkId: provider.networkId.stellarNetworkId)
        var created = false
        creationWatch = Stellar.paymentWatch(account: account.publicAddress, lastEventId: nil, node: node)
        
        creationWatch!.emitter.on(next: { [weak self] _ in
            created = true
            self?.creationWatch = nil
            self?.creationLinkBag = LinkBag()
            p.signal(())
        }).add(to: creationLinkBag)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
            if created == false {
                self?.creationWatch = nil
                self?.creationLinkBag = LinkBag()
                p.signal(KinEcosystemError.service(.timeout, nil))
            }
        }

        return p
    }
}
