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
            }.then { htmlResult, order, memo -> Promise<(Data, PaymentMemoIdentifier, OpenOrder)> in
                let result = EarnResult(content: htmlResult)
                let content = try JSONEncoder().encode(result)
                return core.network.dataAtPath("orders/\(order.id)", method: .post, body: content)
                    .then { data in
                        Promise<(Data, PaymentMemoIdentifier, OpenOrder)>().signal((data, memo, order))
                }
            }.then { data, memo, order -> Promise<(Data, PaymentMemoIdentifier, OpenOrder)> in
                return core.data.changeObjects(of: Offer.self, changeBlock: { offers in
                    offers.first?.pending = true
                }, with: NSPredicate(with:["id": offerId]))
                    .then {
                        Promise<(Data, PaymentMemoIdentifier, OpenOrder)>().signal((data, memo, order))
                }
            }.then { data, memo, order -> Promise<PaymentMemoIdentifier> in
                return core.blockchain.waitForNewPayment(with: memo)
                    .then {
                        Promise<PaymentMemoIdentifier>().signal(memo)
                }
            }.then { memo in
                core.blockchain.stopWatchingForNewPayments(with: memo)
            }.error { error in
                if case let EarnOfferHTMLError.js(jsError) = error {
                    logError("earn flow JS error: \(jsError)")
                } else {
                    switch error {
                    case is KinError,
                         is BlockchainError,
                         EarnOfferHTMLError.invalidJSResult:
                        core.blockchain.stopWatchingForNewPayments()
                        if let order = openOrder {
                            core.network.delete("orders/\(order.id)").then {
                                logInfo("order canceled: \(order.id)")
                                }.error { error in
                                    logError("error canceling order: \(order.id)")
                            }
                        }
                        logError("earn flow error: \(error)")
                    default:
                        logError("earn flow error: \(error)")
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
                                if let completedOrder = orders.first {
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
                let retries: [UInt32] = [2, 4, 8, 16, 32]
                
                DispatchQueue.global().async {
                    var retryIndex = 0
                    var success = false
                    while success == false && retryIndex < retries.count {
                        
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()
                        
                        logVerbose("attempting to receive order with complete/failed status (\(retryIndex + 1)/\(retries.count)")
                        core.network.dataAtPath("orders/\(order.id)")
                            .then { data in
                                core.data.read(Order.self, with: data, readBlock: { networkOrder in
                                    success = (networkOrder.orderStatus != .pending)
                                })
                            }.then {
                                if success == false {
                                    sleep(retries[retryIndex])
                                    retryIndex = retryIndex + 1
                                    if retryIndex == 5 {
                                        // set balance message to "Sorry - this may take some time"
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
                        // set balance message to "Oops! Something went wrong"
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
                                if let completedOrder = orders.first {
                                    completedOrder.orderStatus = .completed
                                }
                            }, with: NSPredicate(with: ["id": order.id]))
                        }
                        openOrder = nil
                }
                
        }
        
    }
    
}
