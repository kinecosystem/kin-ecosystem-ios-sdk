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
    var offersViewModel: OffersListViewModel?
    
    init(network: EcosystemNet, dataStore: EcosystemData) {
        self.network = network
        self.dataStore = dataStore
    }
    
    func updateOffers() -> Promise<Void> {
        return network.offers().then { data in
            self.updateOffersViewModel(data: data)
            }.then { data in
                self.dataStore.syncOffersFromNetworkData(data: data)
        }
    }
    
    fileprivate func updateOffersViewModel(data: Data) -> Promise<Data> {
        let p = Promise<Data>()
        do {
            self.offersViewModel = try JSONDecoder().decode(OffersListViewModel.self, from: data)
        } catch {
            return p.signal(error)
        }
        return p.signal(data)
    }

}

