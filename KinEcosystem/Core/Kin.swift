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

enum KinEcosystemError: Error {
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
    public func start(apiKey: String, userId: String, jwt: String? = nil, networkId: NetworkId = .testNet) -> Bool {
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
        var url: URL
        switch networkId {
        case .mainNet:
            url = URL(string: "http://api.kinmarketplace.com/v1")!
        default:
            url = URL(string: "http://localhost:3000/v1")!
        }
        network = EcosystemNet(config: EcosystemConfiguration(baseURL: url, apiKey: apiKey, userId: userId, jwt: jwt, publicAddress: blockchain.account.publicAddress))
        // TODO: Login
        started = true
        // TODO: move this to dev initiated (not on start)
        updateOffers()
        return true
    }
    
    public func balance(_ completion: @escaping (Decimal) -> ()) {
        blockchain.balance().then(on: DispatchQueue.main) { balance in
            completion(balance)
            }.error { error in
                logWarn("returning zero for balance because real balance retreive failed, error: \(error)")
                completion(0)
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
        mpViewController.blockchain = blockchain
        let navigationController = KinBaseNavigationController(rootViewController: mpViewController)
        parentViewController.present(navigationController, animated: true)
    }
    
    /// Internal ///
    @discardableResult
    func updateOffers() -> Promise<Void> {
        guard started else {
            logError("Kin not started")
            return Promise<Void>().signal(KinEcosystemError.kinNotStarted)
        }
        return network.offers().then { data in
            self.data.sync(OffersList.self, with: data)
        }
    }
    
    
    
}
