//
//  PaymentManager.swift
//  KinEcosystem
//
//  Created by Alon Genosar on 04/08/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit
import KinMigrationModule
import CoreData

class PaymentManager {

    static private let linkBag = LinkBag()
    static private var core:Core!
    static private var watcher:PaymentWatchProtocol??
    static private var promise = Promise<String>()

    class func resume(core:Core) {
        self.core = core
        guard  watcher == nil else { return }
        watcher = try? self.core.blockchain.account?.watchPayments(cursor:"now")
        self.watcher??.emitter.on(next: { paymentInfo in
            if let p = paymentInfo as? PaymentInfoProtocol {
                if var orderId = p.memoText?.components(separatedBy:"-").last {
                    Flows.updatePayment(orderId: orderId, core: PaymentManager.core)
                        .then({ order in

                        })
                }
            }
        }).add(to: self.linkBag)
    }
    
    class func resign() {
    
        watcher??.emitter.unlink()
        watcher = nil
    }
}
