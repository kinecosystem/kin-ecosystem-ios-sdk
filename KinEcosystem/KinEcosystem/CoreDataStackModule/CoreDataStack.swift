//
//  CoreDataManager.swift
//  CoreDataManager
//
//  Created by Avi Shevin on 23/10/2017.
//  Copyright © 2017 Avi Shevin. All rights reserved.
//

import Foundation
import CoreData

public enum CoreDataStackError: Error {
    case missingModel (String)
}

public typealias CoreDataManagerUpdateBlock = (NSManagedObjectContext, inout Bool) throws -> ()
public typealias CoreDataManagerQueryBlock = (NSManagedObjectContext) -> ()

/**
 `CoreDataStack` is a safe, simple, and easy-to-use Core Data stack.  The focus is on making safe
 Core Data the easy path, thereby avoiding common bugs associated with using multiple contexts.

 `CoreDataStack` performs modifications in a background queue, and offers read-only access to
 the main thread.
 */

public final class CoreDataStack {
    public let viewContext: ReadOnlyMOC

    private let coordinator: NSPersistentStoreCoordinator

    fileprivate let queue = OperationQueue()
    fileprivate let queryQueue = OperationQueue()
    fileprivate var token: AnyObject? = nil
    fileprivate var isShuttingDown = false

    /**
     Create a stack with the given model name, with a store type of `NSSQLiteStoreType`.

     - parameter modelName: The model name within the resource bundle
     */
    convenience public init(modelName: String) throws {
        try self.init(modelName: modelName, storeType: NSSQLiteStoreType)
    }

    /**
     Create a stack with the given model name and store type.

     If `modelURL` is `nil`, the model is searched for in the Main bundle.

     - parameter modelName: The model name within the resource bundle
     - parameter storeType: One of the persistent store types supported by Core Data
     - parameter modelURL: An optional parameter which gives the local URL to the model.
     */
    public init(modelName: String, storeType: String, modelURL: URL? = nil) throws {
        guard let model = CoreDataStack.model(for: modelName, at: modelURL) else {
           throw CoreDataStackError.missingModel(modelName)
        }

        queue.maxConcurrentOperationCount = 1
        queue.name = "cdm.queue"

        queryQueue.maxConcurrentOperationCount = 1
        queryQueue.name = "cdm.queue.query"

        let options: [String: Any] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption: ["journal_mode": "WAL"]
        ]

        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: storeType,
                                           configurationName: nil,
                                           at: CoreDataStack.storageURL(for: modelName),
                                           options: storeType == NSSQLiteStoreType
                                            ? options
                                            : nil)

        viewContext = ReadOnlyMOC(concurrencyType: .mainQueueConcurrencyType)
        viewContext.persistentStoreCoordinator = coordinator
        if #available(iOS 10.0, *) {
            viewContext.mergePolicy = NSMergePolicy.rollback
        }

        token = NotificationCenter
            .default
            .addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave,
                         object: nil,
                         queue: nil) { (notification) in
                            guard let context = notification.object as? NSManagedObjectContext else {
                                return
                            }

                            guard context != self.viewContext &&
                                context.persistentStoreCoordinator == self.viewContext.persistentStoreCoordinator else {
                                    return
                            }

                            self.viewContext.performAndWait {
                                if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                                    updatedObjects.forEach {
                                        self.viewContext
                                            .object(with: $0.objectID)
                                            .willAccessValue(forKey: nil)
                                    }
                                }

                                self.viewContext.mergeChanges(fromContextDidSave: notification)
                            }
        }
    }

    deinit {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
    }

    private static func storageURL(for name: String) -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
            .appendingPathComponent(name)
            .appendingPathExtension("sqlite")
    }

    private static func model(for name: String, at url: URL? = nil) -> NSManagedObjectModel? {
        guard let url = url ?? Bundle.main.url(forResource: name, withExtension: "momd") else {
            return nil
        }

        return NSManagedObjectModel(contentsOf: url)
    }
}

extension CoreDataStack {
    /**
     Shuts down the stack safely, waiting for all operations to complete.  The stack is not usable
     after this method returns.

     This method must be called from the main thread.
     */
    public func shutdown() {
        guard Thread.current == Thread.main else {
            fatalError("Must call from main thread.")
        }

        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }

        token = nil

        isShuttingDown = true

        queue.waitUntilAllOperationsAreFinished()
    }

    /**
     A safe version of the `save()` method; throws when called on the `viewContext`.
     */
    public func save(_ context: NSManagedObjectContext) throws {
        guard context != viewContext else {
            fatalError("Saving the viewContext is illegal.")
        }

        if context.hasChanges {
            try context.save()
        }
    }

    /**
     Submits a block to a background context.  The block receives the context and an `inout` boolean
     that may be set to `false` to discard changes to the context.  An optional completion block may
     be provided.

     **Notes**: The provided context is fresh; managed objects must be loaded into the context prior
     to use.  The `completion` block, if provided, is called from a background thread.  Dispatch work
     to the main thread if necessary.

     - parameter block: A block which performs modifications to Core Data entities
     - parameter completion: A block which is invoked after the context has been saved.  The block
     receives an optional Error, which will be non-`nil` if the block threw an error.
     */
    public func perform(_ block: @escaping CoreDataManagerUpdateBlock, completion: ((Error?) -> ())? = nil) {
        guard isShuttingDown == false else {
            return
        }

        let context = viewContext.backgroundCloneRW
        var shouldSave = true
        var error: Error?

        queue.addOperation {
            context.performAndWait {
                do {
                    try block(context, &shouldSave)

                    if shouldSave {
                        try context.save()
                    }
                }
                catch let e {
                    error = e
                }
            }

            context.killed = true

            completion?(error)
        }
    }

    /**
     Submits a block to a background context.  The block receives the context, which may be used
     to query Core Data, but not to modify the store.

     **Notes**: The provided context is fresh; managed objects must be loaded into the context prior
     to use.

     - parameter block: A block which performs queries of Core Data entities
     */
    public func query(_ block: @escaping CoreDataManagerQueryBlock) {
        guard isShuttingDown == false else {
            return
        }

        let context = viewContext.backgroundCloneRO

        queryQueue.addOperation {
            context.performAndWait {
                block(context)

                context.killed = true
            }
        }
    }

    /**
     Submits a block to the `viewContext`.  The block receives the context, which may be used
     to query Core Data, but not to modify the store.  This method may be called from a
     background thread.

     - parameter block: A block which performs queries of Core Data entities
     */
    public func viewQuery(_ block: CoreDataManagerQueryBlock) {
        guard isShuttingDown == false else {
            return
        }

        viewContext.performAndWait {
            block(viewContext)
        }

        if viewContext.hasChanges {
            fatalError("viewContext should not be modified.")
        }
    }
}

//MARK: - Public - NSManagedObject -

public extension NSManagedObject {
    /**
        Provides the entity's name, used with `NSFetchRequest`.
     */
    public static var entityName: String {
        let className: () -> String = {
            let d = description()

            if d.contains(".") {
                return String(d[d.index(after: d.index(of: ".")!) ..< d.endIndex])
            }

            return d
        }

        if #available(iOS 10.0, *) {
            return self.entity().name ?? className()
        } else {
            return className()
        }
    }
}

//MARK: - Public - NSManagedObjectContext -

public extension NSManagedObjectContext {
    /**
     Loads items matching the given conditions (see `NSPredicate` extensions) into the context.

     - parameter conditions: A dictionary of conditions which will be converted into an `NSPredicate`

     - returns: An array of objects of type `T`
     */
    public func itemsMatching<T : NSManagedObject>(conditions: [String: Any]) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: T.entityName)
        request.predicate = NSPredicate(with: conditions)

        return try self.fetch(request)
    }

    /**
     Loads items matching the given predicate into the context.

     - parameter predicate: A predicate against which to filter the items to load

     - returns: An array of objects of type `T`
     */
    public func itemsMatching<T : NSManagedObject>(predicate: NSPredicate) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: T.entityName)
        request.predicate = predicate

        return try self.fetch(request)
    }

    /**
     Loads an array of items into the context.  Items must be of, or descend from, the type
     `NSManagedObject`.

     - parameter items: The array of items to load

     - returns: An array of objects of type `T`
     */
    public func load<T : NSManagedObject>(items: [T]) throws -> [T] {
        let request = NSFetchRequest<NSManagedObject>(entityName: T.entityName)
        request.predicate = NSPredicate(format: "SELF IN %@", argumentArray: [items])

        return try self.fetch(request) as! [T]
    }

    /**
     Loads an item into the context.  Items must be of, or descend from, the type `NSManagedObject`.

     - parameter item: The item to load

     - returns: An object of type `T`
     */
    public func load<T : NSManagedObject>(item: T) throws -> T {
        return try existingObject(with: item.objectID) as! T
    }

    /**
     Loads an item with the given `objectID` into the context.  Items must be of, or descend from,
     the type `NSManagedObject`.

     - parameter objectID: The `NSManagedObjectID` to load

     - returns: An object of type `T`
     */
    public func load<T : NSManagedObject>(objectID: NSManagedObjectID) throws -> T {
        return try existingObject(with: objectID) as! T
    }
}

//MARK: - Private

private extension NSManagedObjectContext {
    var backgroundCloneRW: KillableMOC {
        let context = KillableMOC(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        if #available(iOS 10.0, *) {
            context.mergePolicy = NSMergePolicy.overwrite
        }

        return context
    }

    var backgroundCloneRO: ReadOnlyMOC {
        let context = ReadOnlyMOC(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        if #available(iOS 10.0, *) {
            context.mergePolicy = NSMergePolicy.rollback
        }

        return context
    }
}

//MARK: - Semi-private classes

public class KillableMOC: NSManagedObjectContext {
    fileprivate var killed = false

    override public func performAndWait(_ block: () -> Void) {
        guard killed == false else {
            fatalError("Dead context reused.")
        }

        super.performAndWait(block)
    }

    override public func perform(_ block: @escaping () -> Void) {
        guard killed == false else {
            fatalError("Dead context reused.")
        }

        super.perform(block)
    }

    override public func fetch(_ request: NSFetchRequest<NSFetchRequestResult>) throws -> [Any] {
        guard killed == false else {
            fatalError("Dead context reused.")
        }

        return try super.fetch(request)
    }
}

public class ReadOnlyMOC: KillableMOC {
    override public func save() throws {
        fatalError("Can't save a read-only context")
    }
}

