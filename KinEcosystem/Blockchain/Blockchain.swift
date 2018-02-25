//
//  Blockchain.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 11/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import KinSDK
import StellarKit

struct BlockchainProvider: ServiceProvider {
    let url: URL
    let networkId: NetworkId
    
    
    init(networkId: NetworkId) {
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
    var activated = false
    let account: KinAccount!
    
    init(networkId: NetworkId) throws {
        let client = try KinClient(provider: BlockchainProvider(networkId: networkId))
        self.client = client
        account = try client.accounts[0] ?? client.addAccount(with: "")
    }
    
    func balance() -> Promise<Decimal> {
        let p = Promise<Decimal>()
        account.balance(completion: { balance, error in
            if let error = error {
                switch error {
                case KinError.internalInconsistency:
                    logError("account can't be quering now (\(error))")
                        // code error
                case KinError.accountDeleted:
                        logError("account state is invalid. Everything should be reset and redone")
                        // probably delete everything and restart
                case KinError.balanceQueryFailed(let queryError):
                    switch queryError {
                    case StellarKit.StellarError.missingAccount:
                        logWarn("account not yet created on network")
                        // tell ecosystem server to create account
                    case StellarKit.StellarError.missingBalance:
                        logWarn("Kin issuer isn't trusted yet")
                        // do onboarding if we're not already doing
                        // account.activate(passphrase: "", completion: <#T##(String?, Error?) -> Void#>)
                    case StellarKit.StellarError.unknownError:
                        logError("stellar server did not respond well. try again later")
                    default:
                        logError("account can't be quering now. try again later (\(error))")
                        // unknown error bad
                    }
                default:
                    logError("account can't be quering now. try again later (\(error))")
                    // unknown error bad
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
    
    // TODO: activate with promise
}

