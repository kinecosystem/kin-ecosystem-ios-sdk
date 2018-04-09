//
//  Blockchain.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 11/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import KinSDK
import KinUtil
import StellarKit
import StellarErrors

struct BlockchainProvider: ServiceProvider {
    let url: URL
    let networkId: KinSDK.NetworkId
    
    init(networkId: KinSDK.NetworkId) {
        self.networkId = networkId
        switch networkId {
        case .mainNet:
            self.url = URL(string: "https://horizon-testnet.stellar.org")!
        case .testNet:
            self.url = URL(string: "https://horizon-testnet.stellar.org")!
        default:
            self.url = URL(string: "https://horizon-testnet.stellar.org")!
        }
    }
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

enum StatfulBalance {
    case pendind(Decimal)
    case errored(Decimal)
    case verified(Decimal)
}

struct CachedBalance: Codable {
    var balance: Decimal
}

class Blockchain {
    
    let client: KinClient
    fileprivate(set) var account: KinAccount!
    private let linkBag = LinkBag()
    private var paymentObservers = [PaymentMemoIdentifier : Observable<Void>]()
    private var watcher: KinSDK.PaymentWatch?
    let onboardEvent = Observable<Bool>()
    fileprivate var localLastBalance: Decimal = 0
    fileprivate var lastBalance: Decimal {
        get {
            if  let data = UserDefaults.standard.data(forKey: "lastBalance"),
                let cachedBalance = try? JSONDecoder().decode(CachedBalance.self, from: data) {
                    return cachedBalance.balance
            }
            return localLastBalance
        }
        set {
            if let data = try? JSONEncoder().encode(CachedBalance(balance: newValue)) {
                UserDefaults.standard.set(data, forKey: "lastBalance")
            }
            localLastBalance = newValue
        }
    }
    fileprivate(set) var currentBalance = Observable<StatfulBalance>()
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
    
    init(networkId: KinSDK.NetworkId) throws {
        let client = try KinClient(provider: BlockchainProvider(networkId: networkId))
        self.client = client
        if Kin.shared.needsReset {
            lastBalance = 0
            try? client.deleteAccount(at: 0)
        }
        account = try client.accounts[0] ?? client.addAccount()
        currentBalance.next(.pendind(lastBalance))
        _ = balance()
    }
    
    func balance() -> Promise<Decimal> {
        let p = Promise<Decimal>()
        account.balance(completion: { [weak self] balance, error in
            if let error = error {
                switch error {
                case KinError.internalInconsistency:
                    logError("account can't be queried now (\(error))")
                case KinError.accountDeleted:
                        logError("account state is invalid. Everything should be reset and redone")
                case KinError.balanceQueryFailed(let queryError):
                    switch queryError {
                    case StellarError.missingAccount:
                        logInfo("account not yet created on network")
                    case StellarError.missingBalance:
                        logInfo("Kin issuer isn't trusted yet")
                    case StellarError.unknownError:
                        logError("stellar server did not respond well. try again later")
                    default:
                        logError("account can't be quering now. try again later (\(error))")
                    }
                default:
                    logError("account can't be quering now. try again later (\(error))")
                }
                self?.currentBalance.next(.errored((self?.lastBalance)!))
                p.signal(error)
            } else if let balance = balance {
                self?.lastBalance = balance
                self?.currentBalance.next(.verified(balance))
                p.signal(balance)
            } else {
                self?.currentBalance.next(.errored((self?.lastBalance)!))
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
                                    self.onboarded = true
                                    p.signal(())
                                }.error { error in
                                    p.signal(error)
                                }
                            } catch {
                                p.signal(error)
                            }
                        case .missingBalance:
                            self.account.activate().then { _ in
                                self.onboarded = true
                                p.signal(())
                            }.error { error in
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
    
    func startWatchingForNewPayments(with memo: PaymentMemoIdentifier) throws {
        guard watcher == nil else {
            logInfo("payment watcher already started, added watch for \(memo)...")
            paymentObservers[memo] = Observable<Void>()
            return
        }
        watcher = try account.watchPayments(cursor: "now")
        watcher?.emitter.on(next: { [weak self] paymentInfo in
            guard let metadata = paymentInfo.memoText else { return }
            guard let match = self?.paymentObservers.first(where: { (memoKey, _) -> Bool in
                memoKey.description == metadata
            })?.value else { return }
            logInfo("payment found in blockchain for \(metadata)...")
            match.next(())
            match.finish()
        }).add(to: linkBag)
        logInfo("added watch for \(memo)...")
        paymentObservers[memo] = Observable<Void>()
    }
    
    func stopWatchingForNewPayments(with memo: PaymentMemoIdentifier? = nil) {
        guard let memo = memo else {
            paymentObservers.removeAll()
            watcher = nil
            logInfo("removed all payment observers")
            return
        }
        paymentObservers.removeValue(forKey: memo)
        if paymentObservers.count == 0 {
            watcher = nil
        }
        logInfo("removed payment observer for \(memo)")
    }
    
    func waitForNewPayment(with memo: PaymentMemoIdentifier, timeout: TimeInterval = 300.0) -> Promise<Void> {
        let p = Promise<Void>()
        guard paymentObservers.keys.contains(where: { key -> Bool in
            key == memo
        }) else {
            return p.signal(BlockchainError.watchNotStarted)
        }
        currentBalance.next(.pendind(lastBalance))
        var found = false
        paymentObservers[memo]?.on(next: { [weak self] _ in
            found = true
            _ = self?.balance()
            p.signal(())
        }).add(to: linkBag)
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
            if !found {
                self?.currentBalance.next(.errored((self?.lastBalance)!))
                p.signal(BlockchainError.watchTimedOut)
            }
        }
        return p
    }
    

}

