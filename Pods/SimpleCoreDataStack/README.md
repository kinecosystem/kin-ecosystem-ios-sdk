# CoreDataStack

CoreDataStack provides a simple all-in-one Core Data stack.  It is designed to make Core Data both safe and easy to use.  For applications which require high performance, via multiple writers, this project is not for you.

CoreDataStack provides a readonly `NSManagedObjectContext` for use in the main thread.  Contexts for writing are vended as needed, and work is serialized on a background queue.

#### Initialization

```swift
public init(modelName: String, storeType: String) throws
```

Initializes a stack with the given model name and store type.

```swift
convenience public init(modelName: String) throws
```

Initializes a stack with the given model name and a store type of `NSSQLiteStoreType`.

## Working with managed objects.

#### Modifying objects

The main workhorse is

```swift
public func perform(_ block: @escaping CoreDataManagerUpdateBlock, completion: (() -> ())? = nil)
```

This method will submit a block to a background context.  After the operation is complete, the completion is called on the same thread as the block.

`CoreDataManagerUpdateBlock` receives a context and a `shouldSave` boolean which may be modified by the block.  When set to `false`, all changes will be discarded.

#### Querying objects

```swift
public func query(_ block: @escaping CoreDataManagerQueryBlock)
```

This method will submit a block which receives a readonly context.  The block runs on a background queue, and is intended for handling work which requires information from Core Data, but which does not need to modify it.  This block runs in parallel with `perform()` blocks.

```swift
public func viewQuery(_ block: CoreDataManagerQueryBlock)
```

This method submits a block on the `viewContext`, and should only be called from the main thread.

## Contexts

Contexts which are used for modifying core data are vendored by the `perform()` method.  These contexts are destroyed after the block completes, and before the completion is invoked.

Contexts which are used for background queries are vendored by the `query()` method.  These contexts are destroyed after the block is complete.  If the context has changes, a `fatalError()` is thrown.

There is a special, persistent context, called the `viewContext`, used for querying Core Data on the main thread.  Changes made by `perform()` contexts are merged into this context when they are saved.

## Predicates

Extensions to the `NSPredicate` class provide several methods and operators to simplify the creation of predicates.

```swift
public static func predicate(for conditions: [String: Any]) -> NSPredicate
```

This method takes a dictionary of key-value pairs.  The keys are properties of the Core Data entity being queried.  The values are those which will satisfy the query.  Conditions are joined together using an `AND` predicate.

#### Examples

```swift
// someKey == 5
predicate(for: ["someKey": 5])
```

```swift
// someKey BETWEEN 5 and 10
predicate(for: ["someKey": 5...10])
```

```swift
// someKey IN [1, 3, 5]
predicate(for: ["someKey", [1, 3, 5]])
```

### Compound predicates

It is also possible to create compound statements using the following methods.

```swift
public func or(_ conditions: [String: Any]) -> NSPredicate

public func or(_ predicate: NSPredicate) -> NSPredicate
```

```swift
public func and(_ conditions: [String: Any]) -> NSPredicate

public func and(_ predicate: NSPredicate) -> NSPredicate
```

Predicates may also be combined using the following operators.

```swift
// AND
public static func && (left: NSPredicate, right: NSPredicate) -> NSPredicate

// OR
public static func || (left: NSPredicate, right: NSPredicate) -> NSPredicate
```

# License

This software is under the MIT license.  See [LICENSE](https://github.com/ashevin/CoreDataStack/blob/master/LICENSE) for details.
