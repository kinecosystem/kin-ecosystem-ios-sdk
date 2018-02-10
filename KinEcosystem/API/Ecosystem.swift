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
    var offersViewModel: [OfferViewModel]?
    var offers: [Offer]?
    
    init(network: EcosystemNet) {
        self.network = network
    }
    
    func updateOffers() -> Promise<Void> {
        let p = Promise<Void>()
        network.offers().then { data in
            self.decodeOffers(from: data)
            }.then { list in
                self.updateOffersViewModel(model: list)
                p.signal(())
        }
        return p
    }
    
    fileprivate func decodeOffers(from data: Data) -> Promise<[Offer]> {
        let p = Promise<[Offer]>()
        do {
            let list = try JSONDecoder().decode(OffersList.self, from: data)
            offers = list.offers
            return p.signal(list.offers)
        } catch {
            return p.signal(error)
        }
    }
    
    fileprivate func updateOffersViewModel(model: [Offer]) {
        offersViewModel = model.map { offer in
            OfferViewModel(from: offer)
        }
    }

}

