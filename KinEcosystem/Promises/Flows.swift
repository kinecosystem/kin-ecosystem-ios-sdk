//
//  Flows.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 20/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CoreDataStack
import StellarKit
import KinSDK
import KinUtil

struct Flows {
    
    static func earn(offerId: String, resultPromise: Promise<String>, core: Core) {
        
        var openOrder: OpenOrder?
        
        core.network.objectAtPath("offers/\(offerId)/orders", type: OpenOrder.self, method: .post)
            .then { order -> Promise<(String, OpenOrder)> in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "WatchOrderNotification"), object: order.id)
                openOrder = order
                return resultPromise
                    .then { htmlResult in
                        Promise<(String, OpenOrder)>().signal((htmlResult, order))
                }
            }.then(on: .main) { htmlResult, order -> Promise<(String, OpenOrder, PaymentMemoIdentifier)> in
                let memo = PaymentMemoIdentifier(appId: core.network.client.config.appId,
                                                 id: order.id)
                return Promise<(String, OpenOrder, PaymentMemoIdentifier)>().signal((htmlResult, order, memo))
            }.then { htmlResult, order, memo in
                try core.blockchain.startWatchingForNewPayments(with: memo)
            }.then { htmlResult, order, memo -> Promise<(PaymentMemoIdentifier, OpenOrder)> in
                let result = EarnResult(content: htmlResult)
                let content = try JSONEncoder().encode(result)
                return core.network.dataAtPath("orders/\(order.id)", method: .post, body: content)
                    .then { data in
                        core.data.save(Order.self, with: data)
                    }.then {
                        Promise<(PaymentMemoIdentifier, OpenOrder)>().signal((memo, order))
                }
            }.then { memo, order -> Promise<(PaymentMemoIdentifier, OpenOrder)> in
                return core.data.changeObjects(of: Offer.self, changeBlock: { offers in
                    offers.first?.pending = true
                }, with: NSPredicate(with:["id": offerId]))
                    .then {
                        Promise<(PaymentMemoIdentifier, OpenOrder)>().signal((memo, order))
                }
            }.then { memo, order -> Promise<PaymentMemoIdentifier> in
                return core.blockchain.waitForNewPayment(with: memo)
                    .then {
                        Promise<PaymentMemoIdentifier>().signal(memo)
                }
            }.then { memo in
                core.blockchain.stopWatchingForNewPayments(with: memo)
            }.error { error in
                core.blockchain.stopWatchingForNewPayments()
                logError("earn flow error: \(error)")
                if let order = openOrder {
                    core.network.delete("orders/\(order.id)").then {
                        logInfo("order canceled: \(order.id)")
                        }.error { error in
                            logError("error canceling order: \(order.id), \(error)")
                    }
                }
                openOrder = nil
            }.finally {
                core.network.dataAtPath("offers")
                    .then { data in
                        core.data.sync(OffersList.self, with: data)
                    }.then {
                        core.network.dataAtPath("orders")
                    }.then { data in
                        core.data.sync(OrdersList.self, with: data)
                    }.then {
                        if let order = openOrder {
                            _ = core.data.changeObjects(of: Order.self, changeBlock: { orders in
                                if let  completedOrder = orders.first,
                                        completedOrder.orderStatus != .failed {
                                    completedOrder.orderStatus = .completed
                                }
                            }, with: NSPredicate(with: ["id": order.id]))
                        }
                        openOrder = nil
                }
        }
        
    }
    
    static func spend(offerId: String, confirmPromise: Promise<Void>, core: Core) {
        
        var openOrder: OpenOrder?
        
        core.network.objectAtPath("offers/\(offerId)/orders", type: OpenOrder.self, method: .post)
            .then { order -> Promise<(String, Decimal, OpenOrder)> in
                openOrder = order
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "WatchOrderNotification"), object: order.id)
                logVerbose("created order \(order.id)")
                return confirmPromise
                    .then {
                        core.data.queryObjects(of: Offer.self, with: NSPredicate(with: ["id" : offerId, "offer_type" : OfferType.spend.rawValue]))
                    }.then { offers in
                        guard   let offer = offers.first,
                            let recipient = offer.blockchain_data?.recipient_address else {
                                return Promise<(String, Decimal, OpenOrder)>().signal(KinError.internalInconsistency)
                        }
                        logVerbose("spend offer id \(offer.id), recipient \(recipient)")
                        return Promise<(String, Decimal, OpenOrder)>().signal((recipient, Decimal(offer.amount), order))
                }
            }.then { recipient, amount, order -> Promise<(String, Decimal, OpenOrder, PaymentMemoIdentifier)> in
                let memo = PaymentMemoIdentifier(appId: core.network.client.config.appId, id: order.id)
                try core.blockchain.startWatchingForNewPayments(with: memo)
                return core.network.dataAtPath("orders/\(order.id)", method: .post)
                    .then { data in
                        core.data.save(Order.self, with: data)
                    }.then {
                        logVerbose("Submitted order \(order.id)")
                        return Promise<(String, Decimal, OpenOrder, PaymentMemoIdentifier)>().signal((recipient, amount, order, memo))
                }
            }.then { recipient, amount, order, memo -> Promise<(String, Decimal, OpenOrder, PaymentMemoIdentifier)> in
                return core.data.changeObjects(of: Offer.self, changeBlock: { offers in
                    if let offer = offers.first {
                        offer.pending = true
                        logVerbose("changed offer \(offer.id) status to pending")
                    }
                }, with: NSPredicate(with: ["id" : offerId]))
                    .then {
                        Promise<(String, Decimal, OpenOrder, PaymentMemoIdentifier)>().signal((recipient, amount, order, memo))
                }
            }.then { recipient, amount, order, memo -> Promise<(PaymentMemoIdentifier, OpenOrder)> in
                return core.blockchain.account.sendTransaction(to: recipient, kin: amount, memo: memo.description)
                    .then { _ in
                        logVerbose("\(amount) kin sent to \(recipient)")
                        return Promise<(PaymentMemoIdentifier, OpenOrder)>().signal((memo, order))
                }
            }.then { memo, order -> Promise<(PaymentMemoIdentifier, OpenOrder)> in
                return core.blockchain.waitForNewPayment(with: memo)
                    .then {
                        Promise<(PaymentMemoIdentifier, OpenOrder)>().signal((memo, order))
                }
            }.then { memo, order -> Promise<Void> in
                core.blockchain.stopWatchingForNewPayments(with: memo)
                let p = Promise<Void>()
                let retries: [UInt32] = [2, 4, 8, 16, 32, 32, 32, 32]
                
                DispatchQueue.global().async {
                    var retryIndex = -1
                    var success = false
                    while success == false && retryIndex < retries.count {
                        
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()
                        
                        logVerbose("attempting to receive order with complete/failed status (\(retryIndex + 1)/\(retries.count)")
                        core.network.dataAtPath("orders/\(order.id)")
                            .then { data in
                                core.data.read(Order.self, with: data, readBlock: { networkOrder in
                                    success = (networkOrder.orderStatus != .pending)
                                    logVerbose("order \(networkOrder.id) status: \(networkOrder.orderStatus), result: \((networkOrder.result as? CouponCode)?.coupon_code != nil ? "👍🏼" : "nil")")
                                })
                            }.then {
                                if success == false {
                                    retryIndex = retryIndex + 1
                                    if retryIndex < retries.count {
                                        sleep(retries[retryIndex])
                                    }
                                    if retryIndex == 5 || retryIndex == retries.count {
                                        dispatchGroup.enter()
                                        core.data.changeObjects(of: Order.self, changeBlock: { orders in
                                            if let order = orders.first {
                                                order.orderStatus = retryIndex == 5 ? .delayed : .failed
                                            }
                                        }, with: NSPredicate(with: ["id":order.id]))
                                            .finally {
                                                dispatchGroup.leave()
                                        }
                                    }
                                }
                            }.finally {
                                dispatchGroup.leave()
                        }
                        
                        dispatchGroup.wait()
                        
                    }
                    if success {
                        logVerbose("got order with non pending state")
                        p.signal(())
                    } else {
                        p.signal(KinError.internalInconsistency)
                    }
                }
                return p
            }.error { error in
                if case SpendOfferError.userCanceled = error  {
                    logVerbose("user canceled spend")
                } else {
                    logError("\(error)")
                    core.blockchain.stopWatchingForNewPayments()
                }
                _ = core.blockchain.balance()
                if let order = openOrder {
                    core.network.delete("orders/\(order.id)").then {
                        logInfo("order canceled: \(order.id)")
                        }.error { error in
                            logError("error canceling order: \(order.id)")
                    }
                }
                openOrder = nil
            }.finally {
                core.network.dataAtPath("offers")
                    .then { data in
                        core.data.sync(OffersList.self, with: data)
                    }.then {
                        core.network.dataAtPath("orders")
                    }.then { data in
                        core.data.sync(OrdersList.self, with: data)
                    }.then {
                        if let order = openOrder {
                            _ = core.data.changeObjects(of: Order.self, changeBlock: { orders in
                                if let  completedOrder = orders.first,
                                        completedOrder.orderStatus != .failed {
                                    completedOrder.orderStatus = .completed
                                }
                            }, with: NSPredicate(with: ["id": order.id]))
                        }
                        openOrder = nil
                }
                
        }
        
    }
    
}
