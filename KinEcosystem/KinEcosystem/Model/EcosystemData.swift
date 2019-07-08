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
import KinCoreSDK

enum EcosystemDataError: Error {
    case internalInconsistency
    case fetchError
    case decodeError
    case encodeError
}

protocol NetworkSyncable: Decodable {
    func update(_ from: Self, in context: NSManagedObjectContext)
    func willDelete() -> Bool
    var syncId: String { get }
    var position: Int32 { get set }
}

protocol EntityPresentor: Decodable {
    associatedtype entity: NSManagedObject, NetworkSyncable
    var entities: [entity]? { get }
}

typealias DataChangeBlock<T> = (NSManagedObjectContext, [T]) -> ()

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
            guard let networkEntities = try decoder.decode(presentorType, from: data).entities else {
                shouldSave = false
                p.signal(KinError.internalInconsistency)
                return
            }
            
            // set entities order based on network's order return
            networkEntities.enumerated().forEach({ (arg) in
                var (index, entity) = arg
                entity.position = Int32(index)
            })
            
            // network entities are already inserted by their decoders
            
            for diskEntity in diskEntities {
                if let networkEntity = networkEntities.first(where: { entity -> Bool in
                    entity.syncId == diskEntity.syncId
                }) {
                    diskEntity.update(networkEntity, in: context)
                    context.delete(networkEntity)
                } else {
                    if diskEntity.willDelete() {
                        context.delete(diskEntity)
                    }
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
    
    func read<T>(_ type:T.Type, with data: Data, readBlock: ((T) -> ())?) -> Promise<Void> where T : NSManagedObject & NetworkSyncable {
        
        let p = Promise<Void>()
        
        self.stack.perform({ context, shouldSave in
            
            shouldSave = false
            let decoder = JSONDecoder()
            decoder.userInfo[.context] = context
            let networkEntity = try decoder.decode(type, from: data)
            
            readBlock?(networkEntity)
            context.delete(networkEntity)
            
        }) { error in
            if let stackError = error {
                p.signal(stackError)
            } else {
                p.signal(())
            }
        }
        
        return p
        
    }
    
    func save<T>(_ type:T.Type, with data: Data) -> Promise<Void> where T : NSManagedObject & NetworkSyncable {
        
        let p = Promise<Void>()
        
        self.stack.perform({ context, shouldSave in
            
            let request = NSFetchRequest<T>(entityName: String(describing: T.self))
            let diskEntities = try context.fetch(request)
            
            let decoder = JSONDecoder()
            decoder.userInfo[.context] = context
            let networkEntity = try decoder.decode(type, from: data)
            
            if let diskEntity = diskEntities.first(where: { entity -> Bool in
                entity.syncId == networkEntity.syncId
            }) {
                diskEntity.update(networkEntity, in: context)
                context.delete(networkEntity)
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
    
    @discardableResult
    func queryObjects<T: NSFetchRequestResult>(of type: T.Type, with predicate: NSPredicate? = nil, queryBlock: @escaping ([T]) -> ()) -> Promise<Void> {
        let p = Promise<Void>()
        stack.query { context in
            let request = NSFetchRequest<T>(entityName: String(describing: type))
            request.predicate = predicate
            do {
                let objects = try context.fetch(request)
                queryBlock(objects)
                p.signal(())
            } catch {
                p.signal(error)
            }
        }
        return p
    }
    
    func changeObjects<T: NSFetchRequestResult>(of type: T.Type, changeBlock: @escaping DataChangeBlock<T>, with predicate: NSPredicate? = nil) -> Promise<Void> {
        let p = Promise<Void>()
        stack.perform({ context, shouldSave in
            let request = NSFetchRequest<T>(entityName: String(describing: type))
            request.predicate = predicate
            let objects = try context.fetch(request)
            changeBlock(context, objects)
        }) { error in
            if let stackError = error {
                p.signal(stackError)
            } else {
                p.signal(())
            }
        }
        return p
    }
    
}

