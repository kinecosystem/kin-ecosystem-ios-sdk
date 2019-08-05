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
import CoreDataStack
protocol ObserverProtocol: class  {

}
typealias ObserverType = NSObject & ObserverProtocol
typealias PaymentManagerCallback = (Order)->Void
class PaymentManager: NSObject {
    static private let linkBag = LinkBag()
    static private var core:Core!
    static private var watcher:PaymentWatchProtocol??
    static private var promise = Promise<String>()
    static private var observers = [ObserverType]()
    class func add(observer:ObserverProtocol) {

    }
    //TODO: implement remove observer
//    class func remove(observer:@escaping PaymentManagerCallback) {
//          PaymentManager.observers.remove(at:index)
//    }
    class func resume(core:Core) {
        print(linkBag)
        self.core = core
        guard  watcher == nil else { return }
        watcher = try? self.core.blockchain.account?.watchPayments(cursor:"now")
        print(watcher)
            self.watcher??.emitter.on(next: { paymentInfo in
                let p = paymentInfo as! WrappedKinCorePaymentInfo
                if var orderId = p.memoText?.components(separatedBy:"-").last {
                Flows.updatePayment(orderId: orderId, core: PaymentManager.core)
                    .then({ (order) in
                        self.observers.forEach({ observer in
                            observer(order)
                        })
                    })
                }
            }).add(to: self.linkBag)
    }
    class func resign() {
         watcher??.emitter.unlink()
    }
}
