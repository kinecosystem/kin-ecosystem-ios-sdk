//
//  EarnPromise.swift
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

class EarnPromise {
    
    var openOrder: OpenOrder?
    
    func earn(offerId: String, resultPromise: Promise<String>, core: Core) {
        
        core.network.objectAtPath("offers/\(offerId)/orders", type: OpenOrder.self, method: .post)
            .then { [weak self] order -> Promise<(String, OpenOrder)> in
                self?.openOrder = order
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
            }.then { [weak self] data, memo, order -> Promise<(Data, PaymentMemoIdentifier, OpenOrder)> in
                self?.openOrder = nil
                return core.data.changeObjects(of: Offer.self, changeBlock: { offers in
                        offers.first?.pending = true
                    }, with: NSPredicate(with:["id": offerId])).then {
                        core.data.save(Order.self, with: data)
                    }.then {
                            Promise<(Data, PaymentMemoIdentifier, OpenOrder)>().signal((data, memo, order))
                    }
            }.then { data, memo, order -> Promise<(Data, PaymentMemoIdentifier, OpenOrder)> in
                return core.blockchain.waitForNewPayment(with: memo)
                    .then {
                        Promise<(Data, PaymentMemoIdentifier, OpenOrder)>().signal((data, memo, order))
                }
            }.then { data, memo, order in
                return core.data.changeObjects(of: Order.self, changeBlock: { orders in
                    if let completedOrder = orders.first {
                        completedOrder.orderStatus = .completed
                    }
                }, with: NSPredicate(with: ["id": order.id]))
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
                         is EarnOfferHTMLError:
                        core.blockchain.stopWatchingForNewPayments()
                        logError("earn flow error: \(error)")
                    default:
                        logError("earn flow error: \(error)")
                    }
                }
            }.finally { [weak self] in
                if let order = self?.openOrder {
                    core.network.delete("orders/\(order.id)").then {
                        logInfo("order canceled: \(order.id)")
                        }.error { error in
                            logError("error canceling order: \(order.id)")
                    }
                }
                self?.openOrder = nil
                core.network.dataAtPath("offers").then { data in
                    core.data.sync(OffersList.self, with: data)
                }
        }
        
        
    }
    
}
