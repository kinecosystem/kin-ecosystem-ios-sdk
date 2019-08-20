//
//  EntityWatcher.swift
//  CoreDataStack
//
//  Created by Avi Shevin on 07/12/2017.
//  Copyright © 2017 Avi Shevin. All rights reserved.
//

import Foundation
import CoreData

/**
 This class provides a generics and block-based API for `NSFetchedResultsController`.
 */

public final class EntityWatcher<T : NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    /**
     The type to which the managed objects will be cast.  This will be the object type received in
     the `Change` paramater of the `change` event handler.
     */
    public typealias Entity = T
    public typealias EventHandler = (Change?) -> Void

    /**
    `Events` mirrors the methods of `NSFetchedResultsControllerDelegate`.  An application may
     register for just those events it is interested in.
     */
    public enum Event {
        /// The `willChange` handler is invoked in response to `controllerWillChangeContent(:)`.
        case willChange

        /// The `change` handler is invoked in response to `controller(:didChange::::)`.
        case change

        /// The `didChange` handler is invoked in response to `controllerDidChangeContent(:)`.
        case didChange
    }

    /**
     This struct packages the parameters of the `controller(:didChange::::)` delegate method.
     */
    public struct Change {
        /// The `NSManagedObject` which changed
        public let entity: Entity

        /// The type of change
        public let type: NSFetchedResultsChangeType

        /// The index path of the changed object (this value is nil for insertions)
        public let indexPath: IndexPath?

        /// The destination path for the object for insertions or moves (this value is nil for a deletion)
        public let newIndexPath: IndexPath?
    }

    private let frc: NSFetchedResultsController<Entity>

    private var willChangeBlock: EventHandler?
    private var changeBlock: EventHandler?
    private var didChangeBlock: EventHandler?

    /**
     Create an instance of `EntityWatcher` with a simple sort descriptor.

     - parameter predicate: The predicate for the fetched results controller's request
     - parameter sortKey: The key to be used for the sort descriptor
     - parameter ascending: Determines the order in which results are sorted.  Defaults to `true`
     - parameter context: The `NSManagedObjectContext` in which changes should be observed
     */
    convenience public init(predicate: NSPredicate,
                            sortKey: String,
                            ascending: Bool = true,
                            context: NSManagedObjectContext) throws {
        try self.init(predicate: predicate,
                      sortDescriptors: [NSSortDescriptor(key: sortKey, ascending: ascending)],
                      context: context)
    }

    /**
     Create an instance of `EntityWatcher`.

     - parameter predicate: The predicate for the fetched results controller's request
     - parameter sortDescriptors: An array of `NSSortDescriptor` for sorting the results
     - parameter context: The `NSManagedObjectContext` in which changes should be observed
     */
    public init(predicate: NSPredicate,
                sortDescriptors: [NSSortDescriptor],
                context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<Entity>(entityName: Entity.entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        frc = NSFetchedResultsController<Entity>(fetchRequest: request,
                                                 managedObjectContext: context,
                                                 sectionNameKeyPath: nil,
                                                 cacheName: nil)

        super.init()

        frc.delegate = self

        try frc.performFetch()
    }

    /**
     This method registers a handler for the given `Event`.

     - parameter event: The `Event` for which the handler is invoked
     - parameter handler: The event handler.  For `willChange` and `didChange` events, the `Change` parameter is `nil`.
     */
    public func on(_ event: Event, handler: @escaping EventHandler) {
        switch event {
        case .willChange: willChangeBlock = handler
        case .change: changeBlock = handler
        case .didChange: didChangeBlock = handler
        }
    }

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        willChangeBlock?(nil)
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                           didChange anObject: Any,
                           at indexPath: IndexPath?,
                           for type: NSFetchedResultsChangeType,
                           newIndexPath: IndexPath?) {
        guard let object = anObject as? Entity else {
            fatalError("How did that happen?!")
        }

        changeBlock?(Change(entity: object, type: type, indexPath: indexPath, newIndexPath: newIndexPath))
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        didChangeBlock?(nil)
    }
}
