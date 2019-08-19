//
//  NSPredicate+extensions.swift
//  CoreDataManager
//
//  Created by Avi Shevin on 23/10/2017.
//  Copyright © 2017 Avi Shevin. All rights reserved.
//

import Foundation

/**
 A collection of convenience methods to ease the creation of simple predicates.  The primary
 simplification is the `conditions` dictionary.  This dictionary consists of key-value pairs in
 which the key is a property and the value is the parameter the property must match to satisfy the
 predicate.

 - Scalar values generate an equality predicate (`==`).
 - Sets or arrays generate a contains predicate (`IN`).
 - Ranges generate a between predicate (open range: `K >= X && K < Y`; closed range: `K >= X && K <= Y`).
 */

public extension NSPredicate {
    /**
     The constructor takes a dictionary of key-value pairs in which the key is a property of the
     object to be filtered, and will be matched against the given property.  Multiple key-value pairs
     are joined using the `AND` operator.

     - Scalar values generate an equality predicate (`==`).
     - Sets or arrays generate a contains predicate (`IN`).
     - Ranges generate a between predicate (open range: `K >= X && K < Y`; closed range: `K >= X && K <= Y`).

     - parameter conditions: The dictionary of key-value pairs which will form the body of the predicate
     */
    public convenience init(with conditions: [String: Any]) {
        var predicateFormats = [String]()
        var predicateArgs = [Any]()

        for (key, value) in conditions {
            let (format, args) = NSPredicate.predicateFormat(for: key, value: value)

            predicateFormats.append(format)

            args.forEach { predicateArgs.append($0) }
        }

        var predicateString = predicateFormats[0]
        for i in 1..<predicateFormats.count {
            predicateString += " AND " + predicateFormats[i]
        }

        self.init(format: predicateString, argumentArray: predicateArgs)
    }

    /**
     Returns a predicate which combines the receiver with a predicate, formed by the given
     conditions, with the `AND` operator.

     - parameter conditions: The dictionary of key-value pairs which will form the body of the predicate
     */
    @nonobjc public func and(_ conditions: [String: Any]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [self, NSPredicate(with: conditions)])
    }

    /**
     Returns a predicate which combines the receiver with a predicate, formed by the given
     conditions, with the `OR` operator.

     - parameter conditions: The dictionary of key-value pairs which will form the body of the predicate
     */
    @nonobjc public func or(_ conditions: [String: Any]) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: [self, NSPredicate(with: conditions)])
    }

    /**
     Returns a predicate which combines the receiver with the given predicate, using the `AND`
     operator.

     - parameter predicate: The predicate to combine with the receiver
     */
    @nonobjc public func and(_ predicate: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [self, predicate])
    }

    /**
     Returns a predicate which combines the receiver with the given predicate, using the `OR`
     operator.

     - parameter predicate: The predicate to combine with the receiver
     */
    @nonobjc public func or(_ predicate: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: [self, predicate])
    }

    /**
     Returns a predicate which negates the receiver.
     */
    public func not() -> NSPredicate {
        return NSCompoundPredicate(notPredicateWithSubpredicate: self)
    }

    public static func && (left: NSPredicate, right: NSPredicate) -> NSPredicate {
        return left.and(right)
    }

    public static func || (left: NSPredicate, right: NSPredicate) -> NSPredicate {
        return left.or(right)
    }

    public static func && (left: NSPredicate, right: [String: Any]) -> NSPredicate {
        return left.and(right)
    }

    public static func || (left: NSPredicate, right: [String: Any]) -> NSPredicate {
        return left.or(right)
    }

    public static prefix func ! (term: NSPredicate) -> NSPredicate {
        return term.not()
    }
}

private extension NSPredicate {
    static func predicateFormat(for key: String, value: Any) -> (String, [Any]) {
        if value is CountableClosedRange<Int> {
            let range = value as! CountableClosedRange<Int>

            return closedRangePredicateFormat(key: key, value: range)
        }
        else if value is CountableRange<Int> {
            let range = value as! CountableRange<Int>

            return openRangePredicateFormat(key: key, value: range)
        }
        else if value is Set<AnyHashable> || value is Array<AnyHashable> {
            return inPredicateFormat(key: key, value: value)
        }
        else {
            return equalPredicateFormat(key: key, value: value)
        }
    }

    static func equalPredicateFormat(key: String, value: Any) -> (String, [Any]) {
        if key.lowercased() == "self" {
            return ("SELF == %@", [value])
        }

        return ("%K == %@", [key, value])
    }

    static func inPredicateFormat(key: String, value: Any) -> (String, [Any]) {
        if key.lowercased() == "self" {
            return ("SELF IN %@", [value])
        }

        return ("%K IN %@", [key, value])
    }

    static func closedRangePredicateFormat(key: String, value: CountableClosedRange<Int>) -> (String, [Any]) {
        let lower = value.lowerBound
        let upper = value.upperBound

        if key.lowercased() == "self" {
            return ("SELF >= %@ && SELF <= %@", [lower, upper])
        }

        return ("%K >= %@ && %K <= %@", [key, lower, key, upper])
    }

    static func openRangePredicateFormat(key: String, value: CountableRange<Int>) -> (String, [Any]) {
        let lower = value.lowerBound
        let upper = value.upperBound

        if key.lowercased() == "self" {
            return ("SELF >= %@ && SELF < %@", [lower, upper])
        }

        return ("%K >= %@ && %K < %@", [key, lower, key, upper])
    }
}
