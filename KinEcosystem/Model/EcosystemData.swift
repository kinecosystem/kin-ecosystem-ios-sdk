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

protocol NetworkSyncable: Decodable {
    func update(_ from: Self)
    var syncId: String { get }
}

protocol EntityPresentor: Decodable {
    associatedtype entity: NSManagedObject, NetworkSyncable
    var entities: [entity] { get }
}

class EcosystemData {
    
    let stack: CoreDataStack
    
    init(modelName: String, modelURL: URL, storeType: String = NSInMemoryStoreType) throws {
        stack = try CoreDataStack(modelName: modelName, storeType: storeType, modelURL: modelURL)
    }
    
    func sync<E: EntityPresentor>(_ presentorType: E.Type, with data: Data) -> Promise<Void> {
        
        let p = Promise<Void>()
        
        self.stack.perform({ context, shouldSave in
            
            let decoder = JSONDecoder()
            decoder.userInfo[.context] = context
            
            let request = NSFetchRequest<E.entity>(entityName: String(describing: E.entity.self))
            let diskEntities = try context.fetch(request)
            let networkEntities = try decoder.decode(presentorType, from: data).entities
            
            for networkEntity in networkEntities {
                context.insert(networkEntity)
            }
            
            for diskEntity in diskEntities {
                if let networkEntity = networkEntities.first(where: { entity -> Bool in
                    entity.syncId == diskEntity.syncId
                }) {
                    diskEntity.update(networkEntity)
                    context.delete(networkEntity)
                } else {
                    context.delete(diskEntity)
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
    
    func objects<T: NSFetchRequestResult>(of type: T.Type) -> Promise<[T]> {
        let p = Promise<[T]>()
        stack.query { context in
            let request = NSFetchRequest<T>(entityName: String(describing: type))
            guard let objects = try? context.fetch(request) else {
                p.signal(EcosystemDataError.fetchError)
                return
            }
            p.signal(objects)
        }
        return p
    }
    
    // Testing
    
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

