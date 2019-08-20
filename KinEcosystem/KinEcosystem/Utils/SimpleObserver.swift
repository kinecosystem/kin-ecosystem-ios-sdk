//
//  Alon.swift
//  KinEcosystem
//
//  Created by MNM on 06/08/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit

protocol SimpleObserverProtocol {
    var id : Int { get set }
}

protocol SimpleObservableProtocol  {
    var observers : [SimpleObserverProtocol] { get set }
    func addObserver(_ observer: SimpleObserverProtocol)
    func removeObserver(_ observer: SimpleObserverProtocol)
    func notifyObservers(_ observers: [SimpleObserverProtocol])
}

protocol SimpleStaticObservableProtocol  {
    static var observers : [SimpleObserverProtocol] { get set }
    static func addObserver(_ observer: SimpleObserverProtocol)
    static func removeObserver(_ observer: SimpleObserverProtocol)
    static func notifyObservers(_ observers: [SimpleObserverProtocol])
}

class SimpleObservable<T> {
    typealias CompletionHandler = ((T) -> Void)

    var value : T {
        didSet {
            self.notifyObservers(self.observers)
        }
    }

    var observers : [Int : CompletionHandler] = [:]

    init(value: T) {
        self.value = value
    }

    func addObserver(_ observer: SimpleObserverProtocol, completion: @escaping CompletionHandler) {
        self.observers[observer.id] = completion
    }

    func removeObserver(_ observer: SimpleObserverProtocol) {
        self.observers.removeValue(forKey: observer.id)
    }

    func notifyObservers(_ observers: [Int : CompletionHandler]) {
        observers.forEach({ $0.value(value) })
    }

    deinit {
        observers.removeAll()
    }
}
