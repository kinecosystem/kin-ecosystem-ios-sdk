//
//
//  Ecosystem.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//


import Foundation



class Ecosystem {
    
    let network: EcosystemNet
    let dataStore: EcosystemData
    
    init(network: EcosystemNet, dataStore: EcosystemData) {
        self.network = network
        self.dataStore = dataStore
    }
    
    func updateOffers() -> Promise<Void> {
        let p = Promise<Void>()
        network.offers()
            .then { data in
                self.dataStore.syncOffersFromNetworkData(data: data)
            }.then {
                p.signal(())
            }.error { error in
                p.signal(error)
        }
        return p
    }

}

