//
//  FetchedResultsCollectionSection.swift
//  CoreDataManager
//
//  Created by Avi Shevin on 24/10/2017.
//  Copyright © 2017 Avi Shevin. All rights reserved.
//

import UIKit
import CoreData

public typealias CollectionCellConfigurationBlock = (UICollectionViewCell, IndexPath) -> ()

public class FetchedResultsCollectionSection: NSObject, NSFetchedResultsControllerDelegate {
    weak var collection: UICollectionView?
    let section: Int
    public let configureBlock: CollectionCellConfigurationBlock?
    var frc: NSFetchedResultsController<NSManagedObject>? {
        didSet {
            frc?.delegate = self

            try? frc?.performFetch()
        }
    }

    public var objectCount: Int {
        return frc?.fetchedObjects?.count ?? 0
    }

    public init(collection: UICollectionView,
                frc: NSFetchedResultsController<NSManagedObject>?,
                configureBlock: CollectionCellConfigurationBlock?) {
        self.collection = collection
        self.section = collection.fetchedResultsSectionCount
        self.frc = frc
        self.configureBlock = configureBlock

        super.init()
        
        frc?.delegate = self
        try? frc?.performFetch()
    }

    public func objectForCollection(at indexPath: IndexPath) -> NSManagedObject? {
        guard let section = frc?.sections?[0],
            let objects = section.objects,
            indexPath.row < objects.count else {
                return nil
        }

        return objects[indexPath.row] as? NSManagedObject
    }

    private var changes = [(Any, IndexPath?, NSFetchedResultsChangeType, IndexPath?)]()

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        changes = Array()
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collection?.performBatchUpdates({
            for (_, indexPath, type, newIndexPath) in changes {
                let ip = IndexPath(row: indexPath?.row ?? 0, section: section)
                let nip = IndexPath(row: newIndexPath?.row ?? 0, section: section)

                switch type {
                case .insert: collection?.insertItems(at: [nip])
                case .delete: collection?.deleteItems(at: [ip])
                case .update: collection?.reloadItems(at: [ip])
                case .move: collection?.moveItem(at: ip, to: nip)
                }
            }
        }, completion: nil)
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                           didChange anObject: Any,
                           at indexPath: IndexPath?,
                           for type: NSFetchedResultsChangeType,
                           newIndexPath: IndexPath?) {
        changes.append((anObject, indexPath, type, newIndexPath))
    }
}

private var sectionsKey = 0

public extension UICollectionView {
    public func add(fetchedResultsSection: FetchedResultsCollectionSection) {
        var sections: NSMutableDictionary? = associatedSections()

        if sections == nil {
            sections = NSMutableDictionary()
            objc_setAssociatedObject(self, &sectionsKey, sections, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        sections?[fetchedResultsSection.section] = fetchedResultsSection
    }

    public func removeFetchedResultsSection(for section: Int) {
        guard let sections = associatedSections() else {
            return
        }

        sections[section] = nil

        if sections.count == 0 {
            objc_setAssociatedObject(self, &sectionsKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func fetchedResultsSection(for section: Int) -> FetchedResultsCollectionSection? {
        guard let sections = associatedSections() else {
            return nil
        }

        guard let frSection = sections[section] as? FetchedResultsCollectionSection else {
            return nil
        }

        return frSection
    }

    public var fetchedResultsSectionCount: Int {
        guard let sections = associatedSections() else {
            return 0
        }

        return sections.count
    }

    public func objectForCollection(at indexPath: IndexPath) -> NSManagedObject? {
        guard let object = fetchedResultsSection(for: indexPath.section)?
            .objectForCollection(at: indexPath) else {
            return nil
        }

        return object
    }

    private func associatedSections() -> NSMutableDictionary? {
        return objc_getAssociatedObject(self, &sectionsKey) as? NSMutableDictionary
    }
}
