//
//
//  EcosystemData.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//

import Foundation
import CoreDataStack
import CoreData

enum EcosystemDataError: Error {
    case fetchError
    case decodeError
}

class EcosystemData {
    
    let stack: CoreDataStack
    
    init(modelName: String, modelURL: URL, storeType: String = NSInMemoryStoreType) throws {
        stack = try CoreDataStack(modelName: modelName, storeType: storeType, modelURL: modelURL)
    }
    
    func syncOffersFromNetworkData(data: Data) -> Promise<Void> {
        
        let p = Promise<Void>()
        
        self.stack.perform({ context, shouldSave in
            
            let decoder = JSONDecoder()
            decoder.userInfo[.context] = context
            
            let request = NSFetchRequest<Offer>(entityName: "Offer")
            let diskOffers = try context.fetch(request)
            let networkOffers = try decoder.decode(OffersList.self, from: data).offers as [Offer]
            
            for offer in networkOffers {
                context.insert(offer)
            }
            
            for diskOffer in diskOffers {
                if let networkOffer = networkOffers.first(where: { offer -> Bool in
                    offer.id == diskOffer.id
                }) {
                    diskOffer.update(networkOffer)
                    context.delete(networkOffer)
                } else {
                    context.delete(diskOffer)
                }
            }
            
            
        }) { error in
            if let stackError = error {
                p.signal(stackError)
            } else {
                p.signal(())
            }
        }
        
        return p
    }
    
    func offers() -> Promise<[Offer]> {
        let p = Promise<[Offer]>()
        stack.query { context in
            let request = NSFetchRequest<Offer>(entityName: "Offer")
            guard let offers = try? context.fetch(request) else {
                p.signal(EcosystemDataError.fetchError)
                return
            }
            p.signal(offers)
        }
        return p
    }
    
    func resetStore() -> Promise<Void> {
        let p = Promise<Void>()
        stack.perform({ (context, shouldSave) in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Offer")
            let offers = try context.fetch(request)
            guard offers.count > 0 else {
                p.signal(())
                return
            }
            offers.forEach({ offer in
                context.delete(offer as! NSManagedObject)
            })
        }) { error in
            if let error = error {
                p.signal(error)
            } else {
                p.signal(())
            }
        }
        return p
    }
}

