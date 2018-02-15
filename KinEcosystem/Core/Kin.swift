//
//
//  Kin.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//

import Foundation
import KinSDK

enum KinError: Error {
    case kinNotStarted
}

public class Kin {
    
    public static let shared = Kin()
    fileprivate(set) var network: EcosystemNet!
    fileprivate(set) var data: EcosystemData!
    fileprivate(set) var blockchain: Blockchain!
    fileprivate(set) var started = false
    
    fileprivate init() { }
    
    @discardableResult
    public func start(apiKey: String, userId: String, networkId: NetworkId = .testNet) -> Bool {
        guard started == false else { return true }
        guard   let modelPath = Bundle.ecosystem.path(forResource: "KinEcosystem",
                                                      ofType: "momd"),
                let store = try? EcosystemData(modelName: "KinEcosystem",
                                               modelURL: URL(string: modelPath)!),
                let chain = try? Blockchain(networkId: networkId) else {
            // TODO: Analytics + no start
            logError("start failed")
            return false
        }
        blockchain = chain
        data = store
        network = EcosystemNet(config: EcosystemConfiguration(baseURL: URL(string: "http://api.kinmarketplace.com/v1")!, apiKey: apiKey, userId: userId))
        // TODO: Login
        started = true
        // TODO: prefetching
        updateOffers()
        return true
    }
    
    public func balance(_ completion: @escaping (Decimal) -> ()) {
        guard started else {
            logError("Kin not started")
            completion(0)
            return
        }
        guard blockchain.activated else {
            logWarn("Kin account queried but isn't active on the blockchain yet")
            completion(0)
            return
        }
        DispatchQueue.global().async {
            guard let account = self.blockchain.client.accounts[0] else {
                logError("Failed to retrieve account")
                completion(0)
                return
            }
            guard let balance = try? account.balance() else {
                logError("Failed to retrieve account balance")
                completion(0)
                return
            }
            completion(balance)
        }
    }
    
    public func launchMarketplace(from parentViewController: UIViewController) {
        guard started else {
            logError("Kin not started")
            return
        }
        
        let mpViewController = MarketplaceViewController(nibName: "MarketplaceViewController", bundle: Bundle.ecosystem)
        mpViewController.data = data
        mpViewController.network = network
        
        let navigationController = UINavigationController(rootViewController: mpViewController)
        parentViewController.present(navigationController, animated: true, completion: nil)
    }
    
    /// Internal ///
    @discardableResult
    func updateOffers() -> Promise<Void> {
        guard started else {
            logError("Kin not started")
            return Promise<Void>().signal(KinError.kinNotStarted)
        }
        return network.offers().then { data in
            self.data.syncOffersFromNetworkData(data: data)
        }
    }
    
    
    
}
