//
//  Promise+extenstions.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 16/04/2019.
//

import KinUtil

public func attemptEx<T>(_ tries: Int, closure: @escaping (Int) throws -> KinUtil.Promise<T>, recover: @escaping (Error) -> KinUtil.Promise<Void>) -> KinUtil.Promise<T> {
    var stopError: Error?
    return attempt(tries) { attemptNum -> Promise<T> in
        let p = Promise<T>()
        if let stop = stopError {
            return p.signal(stop)
        }
        try closure(attemptNum).then { result in
            p.signal(result)
        }.error { error in
            recover(error).error { _ in
                stopError = error
            }.finally {
                p.signal(error)
            }
        }
        return p
    }
}
