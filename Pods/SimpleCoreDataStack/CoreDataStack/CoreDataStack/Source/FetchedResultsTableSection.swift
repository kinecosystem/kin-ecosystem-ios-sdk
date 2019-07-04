//
//  FetchedResultsTableSection.swift
//  CoreDataManager
//
//  Created by Avi Shevin on 24/10/2017.
//  Copyright © 2017 Avi Shevin. All rights reserved.
//

import UIKit
import CoreData

public typealias TableCellConfigurationBlock = (UITableViewCell, IndexPath) -> ()

public protocol TableSection: class {
    var configureBlock: TableCellConfigurationBlock? { get }
    var objectCount: Int { get }
    var section: Int { get }

    func objectForTable(at indexPath: IndexPath) -> NSManagedObject?
}

extension TableSection {
    public func objectForTable(at indexPath: IndexPath) -> NSManagedObject? {
        return nil
    }
}

public class FetchedResultsTableSection: NSObject, TableSection, NSFetchedResultsControllerDelegate {
    weak var table: UITableView?
    public let section: Int
    public let configureBlock: TableCellConfigurationBlock?
    var frc: NSFetchedResultsController<NSManagedObject>? {
        didSet {
            frc?.delegate = self

            try? frc?.performFetch()
        }
    }

    public var objectCount: Int {
        return frc?.fetchedObjects?.count ?? 0
    }

    public init(table: UITableView,
                frc: NSFetchedResultsController<NSManagedObject>?,
                configureBlock: TableCellConfigurationBlock?) {
        self.table = table
        self.section = table.tableSectionCount
        self.frc = frc
        self.configureBlock = configureBlock

        super.init()
        
        frc?.delegate = self
        try? frc?.performFetch()
    }

    public func objectForTable(at indexPath: IndexPath) -> NSManagedObject? {
        guard let section = frc?.sections?[0],
            let objects = section.objects,
            indexPath.row < objects.count else {
                return nil
        }

        return objects[indexPath.row] as? NSManagedObject
    }

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        table?.beginUpdates()
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        table?.endUpdates()
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                           didChange anObject: Any,
                           at indexPath: IndexPath?,
                           for type: NSFetchedResultsChangeType,
                           newIndexPath: IndexPath?) {
        let ip = IndexPath(row: indexPath?.row ?? 0, section: section)
        let nip = IndexPath(row: newIndexPath?.row ?? 0, section: section)

        switch type {
        case .insert: table?.insertRows(at: [nip], with: .automatic)
        case .delete: table?.deleteRows(at: [ip], with: .automatic)
        case .update: table?.reloadRows(at: [ip], with: .none)
        case .move:
            table?.moveRow(at: ip, to: nip)
        }
    }
}

private var sectionsKey = 0

public extension UITableView {
    public func add(tableSection: TableSection) {
        var sections: NSMutableDictionary? = associatedSections()

        if sections == nil {
            sections = NSMutableDictionary()
            objc_setAssociatedObject(self, &sectionsKey, sections, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        sections?[tableSection.section] = tableSection
    }

    public func removeTableSection(for section: Int) {
        guard let sections = associatedSections() else {
            return
        }

        sections[section] = nil

        if sections.count == 0 {
            objc_setAssociatedObject(self, &sectionsKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func tableSection(for section: Int) -> TableSection? {
        guard let sections = associatedSections() else {
            return nil
        }

        guard let frSection = sections[section] as? TableSection else {
            return nil
        }

        return frSection
    }

    public var tableSectionCount: Int {
        guard let sections = associatedSections() else {
            return 0
        }

        return sections.count
    }

    public func objectForTable(at indexPath: IndexPath) -> NSManagedObject? {
        guard let object = tableSection(for: indexPath.section)?.objectForTable(at: indexPath) else {
            return nil
        }

        return object
    }

    private func associatedSections() -> NSMutableDictionary? {
        return objc_getAssociatedObject(self, &sectionsKey) as? NSMutableDictionary
    }
}
