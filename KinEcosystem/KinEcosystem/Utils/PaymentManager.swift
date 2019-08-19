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

    //MARK: StaticObservableProtocol
    static var order = AlonObservable(value: Order())

    //MARK:
    static private let linkBag = LinkBag()
    static private var core:Core!
    static private var watcher:PaymentWatchProtocol??
    static private var promise = Promise<String>()

    //MARK: API
    class func resume(core:Core) {
        self.core = core
        guard  watcher == nil else { return }
        do {
            watcher = try self.core.blockchain.account?.watchPayments(cursor:"now")
            print("1")
            self.watcher??.emitter.on(next: { paymentInfo in
                 print("2")
                if let p = paymentInfo as? PaymentInfoProtocol {
                    if var orderId = p.memoText?.components(separatedBy:"-").last {
                        Flows.updatePayment(orderId: orderId, core: PaymentManager.core)
                            .then({ order in
                                PaymentManager.order.value = order
                            })
                    }
                }
            }).add(to: self.linkBag)

        } catch {
             print("watcher error",error)
        }
    }
    class func resign() {
        watcher??.emitter.unlink()
        watcher = nil
    }
}
