//
// Observables.swift
// KinUtil
//
// Created by Kin Foundation.
// Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import Dispatch

public final class StatefulObserver<Value>: Observable<Value> {
    public private(set) var value: Value?

    @discardableResult
    override public func on(queue: DispatchQueue? = nil,
                            next: @escaping (Value) -> Void) -> Observable<Value> {
        let wasZero = buffer.isEmpty

        super.on(queue: queue, next: next)

        if let value = value, wasZero {
            super.next(value)
        }

        return self
    }

    override public func next(_ value: Value) {
        self.value = value

        super.next(value)
    }
}

public final class NotificationObserver: Observable<Notification> {
    private var token: NSObjectProtocol

    init(name: Notification.Name,
         object: Any? = nil,
         center: NotificationCenter = .default,
         queue: OperationQueue? = nil) {
        token = NSObject()

        super.init()

        token = center.addObserver(forName: name,
                                   object: object,
                                   queue: queue,
                                   using: { [weak self] notification in
                                    self?.next(notification)
        })
    }

    deinit {
        NotificationCenter.default.removeObserver(token)
    }
}

public final class KVOObserver<Type, ValueType>: Observable<(new: ValueType, old: ValueType?)> {
    private enum Errors: Error {
        case invalidKeyPath
    }

    private class Observer: NSObject {
        fileprivate weak var kvoObserver: KVOObserver?

        @objc override func observeValue(forKeyPath keyPath: String?,
                                         of object: Any?,
                                         change: [NSKeyValueChangeKey : Any]?,
                                         context: UnsafeMutableRawPointer?) {
            let new = change?[NSKeyValueChangeKey.newKey]
            let old = change?[NSKeyValueChangeKey.oldKey]

            if let new = new as? ValueType {
                kvoObserver?.next((new: new, old: old as? ValueType))
            }
        }
    }

    private class OnDelete: NSObject {
        private let block: () -> ()

        init(block: @escaping () -> ()) {
            self.block = block
        }

        deinit {
            block()
        }
    }

    private let observer: Observer
    private var object: Unmanaged<NSObject>?

    private let keyPath: String

    init(object: NSObject, keyPath: WritableKeyPath<Type, ValueType>, options: NSKeyValueObservingOptions = [.new]) throws {
        guard let stringPath = keyPath._kvcKeyPathString else {
            throw Errors.invalidKeyPath
        }

        self.observer = Observer()
        self.object = Unmanaged.passUnretained(object)
        self.keyPath = stringPath

        super.init()

        observer.kvoObserver = self
        object.addObserver(observer, forKeyPath: self.keyPath, options: options.union([.new]), context: nil)

        let deletion = OnDelete { [weak self] in self?.cancel() }
        objc_setAssociatedObject(object,
                                 Unmanaged.passUnretained(self).toOpaque(),
                                 deletion,
                                 .OBJC_ASSOCIATION_RETAIN)
    }

    private func cancel() {
        object?.takeUnretainedValue().removeObserver(observer, forKeyPath: keyPath)
        object = nil
    }

    deinit {
        cancel()
    }
}
