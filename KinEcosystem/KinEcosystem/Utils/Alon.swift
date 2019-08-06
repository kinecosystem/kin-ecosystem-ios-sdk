//
//  Alon.swift
//  KinEcosystem
//
//  Created by MNM on 06/08/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit

protocol AlonObserverProtocol {
    var id : Int { get set }
}

protocol AlonObservableProtocol  {
    var observers : [AlonObserverProtocol] { get set }
    func addObserver(_ observer: AlonObserverProtocol)
    func removeObserver(_ observer: AlonObserverProtocol)
    func notifyObservers(_ observers: [AlonObserverProtocol])
}
protocol AlonStaticObservableProtocol  {
    static var observers : [AlonObserverProtocol] { get set }
    static func addObserver(_ observer: AlonObserverProtocol)
    static func removeObserver(_ observer: AlonObserverProtocol)
    static func notifyObservers(_ observers: [AlonObserverProtocol])
}

class AlonObservable<T> {

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

    func addObserver(_ observer: AlonObserverProtocol, completion: @escaping CompletionHandler) {
        self.observers[observer.id] = completion
    }

    func removeObserver(_ observer: AlonObserverProtocol) {
        self.observers.removeValue(forKey: observer.id)
    }

    func notifyObservers(_ observers: [Int : CompletionHandler]) {
        observers.forEach({ $0.value(value) })
    }

    deinit {
        observers.removeAll()
    }
}
