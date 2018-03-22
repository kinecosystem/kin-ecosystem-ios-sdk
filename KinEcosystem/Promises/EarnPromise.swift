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
    
    weak var htmlController: EarnOfferViewController?
    var openOrder: OpenOrder?
    
    func earn(with controller: EarnOfferViewController, core: Core) {
        self.htmlController = controller
        core.network.objectAtPath("offers/\(controller.offerId!)/orders", type: OpenOrder.self, method: .post)
            .then { order -> Promise<(String, OpenOrder)> in
                self.openOrder = order
                return controller.earn
                    .then { htmlResult in
                        Promise<(String, OpenOrder)>().signal((htmlResult, order))
                }
            }.then(on: .main) { htmlResult, order -> Promise<(String, OpenOrder, PaymentMemoIdentifier)> in
                if let controller = self.htmlController {
                    controller.dismiss(animated: true) {
                        self.htmlController = nil
                    }
                }
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
                self.openOrder = nil
                return core.data.save(Order.self, with: data)
                    .then {
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
                        Kin.shared.core?.blockchain.stopWatchingForNewPayments()
                        logError("earn flow error: \(error)")
                    default:
                        logError("earn flow error: \(error)")
                    }
                }
            }.finally {
                if let order = self.openOrder {
                    core.network.delete("orders/\(order.id)").then {
                        logInfo("order canceled: \(order.id)")
                        }.error { error in
                            logError("error canceling order: \(order.id)")
                    }
                }
                self.openOrder = nil
                if let controller = self.htmlController {
                    DispatchQueue.main.async {
                        controller.dismiss(animated: true) {
                            self.htmlController = nil
                        }
                    }
                }
        }
    }
    
}
