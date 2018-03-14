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

class Blockchain {
    
    let client: KinClient
    fileprivate(set) var account: KinAccount!
    private var creationWatch: CreationWatch?
    private let linkBag = LinkBag()
    let onboardEvent = Observable<Bool>()
    fileprivate(set) var onboarded: Bool {
        get {
            return account.extra != nil
        }
        set {
            onboardEvent.next(true)
            onboardEvent.finish()
            account.extra = Data()
        }
    }
    
    init(networkId: KinSDK.NetworkId) throws {
        let client = try KinClient(provider: BlockchainProvider(networkId: networkId))
        self.client = client
        if Kin.shared.needsReset {
            try? client.deleteAccount(at: 0)
        }
        account = try client.accounts[0] ?? client.addAccount()
    }
    
    func balance() -> Promise<Decimal> {
        let p = Promise<Decimal>()
        account.balance(completion: { balance, error in
            if let error = error {
                switch error {
                case KinError.internalInconsistency:
                    logError("account can't be queried now (\(error))")
                case KinError.accountDeleted:
                        logError("account state is invalid. Everything should be reset and redone")
                case KinError.balanceQueryFailed(let queryError):
                    switch queryError {
                    case StellarKit.StellarError.missingAccount:
                        logWarn("account not yet created on network")
                    case StellarKit.StellarError.missingBalance:
                        logWarn("Kin issuer isn't trusted yet")
                    case StellarKit.StellarError.unknownError:
                        logError("stellar server did not respond well. try again later")
                    default:
                        logError("account can't be quering now. try again later (\(error))")
                    }
                default:
                    logError("account can't be quering now. try again later (\(error))")
                }
                p.signal(error)
            } else if let balance = balance {
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
                            self.watchCreation().then {
                                    self.activate()
                                }.then {
                                    self.onboarded = true
                                    p.signal(())
                                }.error(handler: { error in
                                    p.signal(error)
                                })
                        case .missingBalance:
                            self.activate().then {
                                self.onboarded = true
                                p.signal(())
                            }.error(handler: { error in
                                p.signal(error)
                            })
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
    
    func activate() -> Promise<Void> {
        let p = Promise<Void>()
        self.account.activate { _, error in
            if let error = error {
                p.signal(error)
                return
            }
            logInfo("Stellar account activated")
            p.signal(())
        }
        return p
    }
    
    func watchCreation() -> Promise<Void> {
        let p = Promise<Void>()
        creationWatch = try? account.watchCreation()
        logInfo("creation watch created, waiting for signal")
        creationWatch?.emitter.on(queue: .main, next: { [weak self] _ in
            self?.creationWatch = nil
            logInfo("Stellar account valid on network")
            p.signal(())
        })
        .add(to: linkBag)
        return p
    }

}

