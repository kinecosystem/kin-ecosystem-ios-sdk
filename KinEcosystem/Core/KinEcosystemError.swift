//
//  KinEcosystemError.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 29/05/2018.
//

import Foundation

public enum KinEcosystemError: Error {
    case startFailed(Error)
    case notStarted
    case onboardFailed(Error)
    case offerConflict(Error)
    case notActivated
    case notFound
    case unknown
    case `internal`(Error)
    case service
    case blockchain(Error)
}
