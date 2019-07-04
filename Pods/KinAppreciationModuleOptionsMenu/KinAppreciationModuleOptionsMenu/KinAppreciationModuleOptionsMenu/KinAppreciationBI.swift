//
//  KinAppreciationBI.swift
//  KinAppreciationModuleOptionsMenu
//
//  Created by Corey Werner on 20/06/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

public protocol KinAppreciationBIDelegate: NSObjectProtocol {
    func kinAppreciationDidAppear()
    func kinAppreciationDidSelect(amount: Decimal)
    func kinAppreciationDidCancel(reason: KinAppreciationCancelReason)
    func kinAppreciationDidComplete()
}

class KinAppreciationBI {
    static let shared = KinAppreciationBI()
    weak var delegate: KinAppreciationBIDelegate?
}
