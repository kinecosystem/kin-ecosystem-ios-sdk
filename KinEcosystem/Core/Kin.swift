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
            return false
        }
        blockchain = chain
        data = store
        network = EcosystemNet(config: EcosystemConfiguration(baseURL: URL(string: "http://api.kinmarketplace.com/v1")!, apiKey: apiKey, userId: userId))
        // TODO: Login
        started = true
        // TODO: prefetching
        return true
    }
    
    /// Internal ///
    
    func updateOffers() -> Promise<Void> {
        return network.offers().then { data in
            self.data.syncOffersFromNetworkData(data: data)
        }
    }
    
}
