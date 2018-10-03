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
import KinUtil
import KinCoreSDK
import StellarErrors

enum OrderStatusError: Error {
    case orderStillPending
    case orderNotFound
    case orderProcessingFailed
}

enum FirstSpendError: Error {
    case spendFailed
}

typealias SDOPFlowPromise = KinUtil.Promise<(String, Decimal, OpenOrder, PaymentMemoIdentifier)>
typealias SDOFlowPromise = KinUtil.Promise<(String, Decimal, OpenOrder)>
typealias SOPFlowPromise = KinUtil.Promise<(String, OpenOrder, PaymentMemoIdentifier)>
typealias POFlowPromise = KinUtil.Promise<(PaymentMemoIdentifier, OpenOrder)>

@available(iOS 9.0, *)
struct Flows {
        
    static func earn(offerId: String,
                     resultPromise: Promise<String>,
                     core: Core) {
        
        var openOrder: OpenOrder?
        var canCancelOrder = true
        let prevBalance = core.blockchain.lastBalance
        
        core.network.objectAtPath("offers/\(offerId)/orders",
            type: OpenOrder.self,
            method: .post)
            .then { order -> Promise<(String, OpenOrder)> in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "WatchOrderNotification"),
                                                object: order.id)
                openOrder = order
                Kin.track { try EarnOrderCreationReceived(offerID: order.offer_id, orderID: order.id) }
                return resultPromise
                    .then { htmlResult in
                        KinUtil.Promise<(String, OpenOrder)>().signal((htmlResult, order))
                }
            }.then(on: .main) { htmlResult, order -> SOPFlowPromise in
                guard let appId = core.network.client.authToken?.app_id else {
                    return SOPFlowPromise().signal(KinEcosystemError.client(.internalInconsistency, nil))
                }
                let memo = PaymentMemoIdentifier(appId: appId,
                                                 id: order.id)
                return SOPFlowPromise().signal((htmlResult, order, memo))
            }.then { htmlResult, order, memo in
                try core.blockchain.startWatchingForNewPayments(with: memo)
            }.then { htmlResult, order, memo -> Promise<(PaymentMemoIdentifier, OpenOrder)> in
                let result = EarnResult(content: htmlResult)
                let content = try JSONEncoder().encode(result)
                return core.network.dataAtPath("orders/\(order.id)",
                    method: .post,
                    body: content)
                    .then { data in
                        Kin.track { try EarnOrderCompletionSubmitted(offerID: order.offer_id, orderID: order.id) }
                        return core.data.save(Order.self, with: data)
                    }.then {
                        canCancelOrder = false
                        return POFlowPromise().signal((memo, order))
                }
            }.then { memo, order -> Promise<(PaymentMemoIdentifier, OpenOrder)> in
                return core.data.changeObjects(of: Offer.self,
                                               changeBlock: { _, offers in
                    offers.first?.pending = true
                }, with: NSPredicate(with:["id": offerId]))
                    .then {
                        POFlowPromise().signal((memo, order))
                }
            }.then { memo, order -> POFlowPromise in
                return core.blockchain.waitForNewPayment(with: memo)
                    .then { txHash in
                        Kin.track { try EarnOrderPaymentConfirmed(orderID: order.id, transactionID: txHash) }
                        return POFlowPromise().signal((memo, order))
                }
            }.then { memo, order -> KinUtil.Promise<OpenOrder> in
                core.blockchain.stopWatchingForNewPayments(with: memo)
                let intervals: [TimeInterval] = [2, 4, 8, 16, 32, 32, 32, 32]
                return attempt(retryIntervals: intervals,
                               closure: { attemptNumber -> Promise<Void> in
                    let p = KinUtil.Promise<Void>()
                    logVerbose("attempt to get earn order with !pending state: (\(attemptNumber)/\(intervals.count + 1))")
                    var pending = true
                    core.network.dataAtPath("orders/\(order.id)")
                        .then { data in
                            core.data.read(Order.self, with: data,
                                           readBlock: { networkOrder in
                                logVerbose("earn order \(networkOrder.id) status: \(networkOrder.orderStatus)")
                                if networkOrder.orderStatus != .pending {
                                    pending = false
                                }
                            }).then {
                                if pending {
                                    if attemptNumber == 5 || attemptNumber == intervals.count + 1 {
                                        logWarn("attempts reached \(attemptNumber)")
                                        _ = core.data.changeObjects(of: Order.self, changeBlock: { _, orders in
                                            if let order = orders.first {
                                                order.orderStatus = attemptNumber == 5 ? .delayed : .failed
                                            }
                                        }, with: NSPredicate(with: ["id":order.id]))
                                    }
                                    p.signal(OrderStatusError.orderStillPending)
                                } else {
                                    p.signal(())
                                }
                            }
                    }
                    return p
                }).then {
                    KinUtil.Promise<OpenOrder>().signal(order)
                }
            }.then { order in
                core.data.queryObjects(of: Offer.self, with: NSPredicate(with: ["id" : order.offer_id])) { result in
                    guard let offer = result.first else {
                        return
                    }
                    if let type = KBITypes.OfferType(rawValue: offer.offerContentType.rawValue) {
                        Kin.track { try EarnOrderCompleted(kinAmount: Double(order.amount), offerID: order.offer_id, offerType: type, orderID: order.id) }
                    }
                }
            }.error { error in
                core.blockchain.stopWatchingForNewPayments()
                logError("earn flow error: \(error)")
                if  case let EcosystemNetError.service(responseError) = error,
                    let url = responseError.httpResponse?.url,
                    url.pathComponents.contains("offers") {
                    Kin.track { try EarnOrderCreationFailed(errorReason: responseError.message ?? "\(responseError.code)", offerID: offerId) }
                }
                Kin.track { try EarnOrderFailed(errorReason: "\(error)", offerID: offerId, orderID: openOrder?.id ?? "") }
                if let order = openOrder, canCancelOrder {
                    if case EarnOfferHTMLError.userCanceled = error {
                        Kin.track { try EarnOrderCancelled(offerID: order.offer_id, orderID: order.id) }
                    }
                    let group = DispatchGroup()
                    group.enter()
                    core.network.delete("orders/\(order.id)").then {
                        logInfo("order canceled: \(order.id)")
                        }.error { error in
                            logError("error canceling order: \(order.id)")
                        }.finally {
                            group.leave()
                    }
                    group.wait()
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
                            _ = core.data.changeObjects(of: Order.self,
                                                        changeBlock: { _, orders in
                                if let  completedOrder = orders.first,
                                    completedOrder.orderStatus != .failed {
                                    completedOrder.orderStatus = .completed
                                }
                            }, with: NSPredicate(with: ["id": order.id]))
                        }
                        openOrder = nil
                }
                if  let prev = prevBalance,
                    let next = core.blockchain.lastBalance,
                    prev.amount != next.amount {
                    Kin.track { try KinBalanceUpdated(previousBalance: (prev.amount as NSDecimalNumber).doubleValue) }
                }
        }
        
    }
    
    static func spend(offerId: String,
                      confirmPromise: Promise<Void>,
                      submissionPromise: Promise<Void>? = nil,
                      successPromise: Promise<String>? = nil,
                      core: Core) {
        
        var openOrder: OpenOrder?
        var canCancelOrder = true
        let prevBalance = core.blockchain.lastBalance
        Kin.track { try SpendOrderCreationRequested(isNative: false, offerID: offerId, origin: .marketplace) }
        core.network.objectAtPath("offers/\(offerId)/orders",
            type: OpenOrder.self,
            method: .post)
            .then { order -> SDOFlowPromise in
                openOrder = order
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "WatchOrderNotification"),
                                                object: order.id)
                logVerbose("created order \(order.id)")
                Kin.track { try SpendOrderCreationReceived(isNative: false, offerID: offerId, orderID: order.id, origin: .marketplace) }
                return confirmPromise
                    .then {
                        var recipient: String? = nil
                        var amount: Decimal? = nil
                        return core.data.queryObjects(of: Offer.self,
                                                      with: NSPredicate(with: ["id" : offerId, "offer_type" : OfferType.spend.rawValue])) { offers in
                                                        guard let offer = offers.first,
                                                            let amountRecipient = offer.blockchain_data?.recipient_address else {
                                                                return
                                                        }
                                                        recipient = amountRecipient
                                                        amount = Decimal(offer.amount)
                            }.then {
                                guard let r = recipient, let a = amount else {
                                    return SDOFlowPromise().signal(KinError.internalInconsistency)
                                }
                                logVerbose("spend offer id \(offerId), recipient \(r)")
                                return SDOFlowPromise().signal((r, a, order))
                        }
                        
                }
            }.then { recipient, amount, order -> SDOPFlowPromise in
                guard let appId = core.network.client.authToken?.app_id else {
                    return SDOPFlowPromise().signal(KinEcosystemError.client(.internalInconsistency, nil))
                }
                let memo = PaymentMemoIdentifier(appId: appId, id: order.id)
                try core.blockchain.startWatchingForNewPayments(with: memo)
                return core.network.dataAtPath("orders/\(order.id)",
                    method: .post)
                    .then { data in
                        Kin.track { try SpendOrderCompletionSubmitted(isNative: false, offerID: offerId, orderID: order.id, origin: .marketplace) }
                        return core.data.save(Order.self, with: data)
                    }.then {
                        canCancelOrder = false
                        logVerbose("Submitted order \(order.id)")
                        if let p = submissionPromise {
                            p.signal(())
                        }
                        return SDOPFlowPromise().signal((recipient, amount, order, memo))
                }
            }.then { recipient, amount, order, memo -> SDOPFlowPromise in
                return core.data.changeObjects(of: Offer.self,
                                               changeBlock: { _, offers in
                    if let offer = offers.first {
                        offer.pending = true
                        logVerbose("changed offer \(offer.id) status to pending")
                    }
                }, with: NSPredicate(with: ["id" : offerId]))
                    .then {
                        SDOPFlowPromise().signal((recipient, amount, order, memo))
                }
            }.then { recipient, amount, order, memo -> POFlowPromise in
                Kin.track { try SpendTransactionBroadcastToBlockchainSubmitted(offerID: order.offer_id, orderID: order.id) }
                return core.blockchain.pay(to: recipient,
                                           kin: amount,
                                           memo: memo.description)
                    .then { txId in
                        Kin.track { try SpendTransactionBroadcastToBlockchainSucceeded(offerID: order.offer_id, orderID: order.id, transactionID: txId) }
                        logVerbose("\(amount) kin sent to \(recipient)")
                        return POFlowPromise().signal((memo, order))
                }
            }.then { memo, order -> POFlowPromise in
                return core.blockchain.waitForNewPayment(with: memo)
                    .then { txHash in
                        return POFlowPromise().signal((memo, order))
                }
            }.then { memo, order -> KinUtil.Promise<OpenOrder> in
                core.blockchain.stopWatchingForNewPayments(with: memo)
                let intervals: [TimeInterval] = [2, 4, 8, 16, 32, 32, 32, 32]
                return attempt(retryIntervals: intervals,
                               closure: { attemptNumber -> Promise<Void> in
                    let p = KinUtil.Promise<Void>()
                    logVerbose("attempt to get spend order with !pending state (and result): (\(attemptNumber)/\(intervals.count + 1))")
                    var pending = true
                    core.network.dataAtPath("orders/\(order.id)")
                        .then { data in
                            core.data.read(Order.self,
                                           with: data,
                                           readBlock: { networkOrder in
                                let hasResult = (networkOrder.result as? CouponCode)?.coupon_code != nil
                                logVerbose("spend order \(networkOrder.id) status: \(networkOrder.orderStatus), result: \(hasResult ? "👍🏼" : "nil")")
                                if (networkOrder.orderStatus != .pending && hasResult) || networkOrder.orderStatus == .failed {
                                    pending = false
                                }
                            }).then {
                                if pending {
                                    if attemptNumber == 5 || attemptNumber == intervals.count + 1 {
                                        logWarn("attempts reached \(attemptNumber)")
                                        _ = core.data.changeObjects(of: Order.self,
                                                                    changeBlock: { _, orders in
                                            if let order = orders.first {
                                                order.orderStatus = attemptNumber == 5 ? .delayed : .failed
                                            }
                                        }, with: NSPredicate(with: ["id":order.id]))
                                    }
                                    p.signal(OrderStatusError.orderStillPending)
                                } else {
                                    p.signal(())
                                }
                            }
                    }
                    return p
                }).then {
                    KinUtil.Promise<OpenOrder>().signal(order)
                }
                
            }.then { order in
                Kin.track { try SpendOrderCompleted(isNative: false, kinAmount: Double(order.amount), offerID: order.offer_id, orderID: order.id, origin: .marketplace) }
            }
            .error { error in
                if case SpendOfferError.userCanceled = error  {
                    logVerbose("user canceled spend")
                    Kin.track { try SpendOrderCancelled(offerID: offerId, orderID: openOrder?.id ?? "") }
                } else {
                    logError("\(error)")
                    core.blockchain.stopWatchingForNewPayments()
                }
                if case KinError.insufficientFunds = error {
                    Kin.track { try SpendTransactionBroadcastToBlockchainFailed(errorReason: "\(error)", offerID: offerId, orderID: openOrder?.id ?? "") }
                } else if case let KinError.paymentFailed(payError) = error {
                    Kin.track { try SpendTransactionBroadcastToBlockchainFailed(errorReason: "\(payError)", offerID: offerId, orderID: openOrder?.id ?? "") }
                    if let order = openOrder {
                        let errorObject = ClientErrorPatch(error: ResponseError(code: 6005,
                                                                                error: "\(payError)",
                                                                                message: nil))
                        if let data = try? JSONEncoder().encode(errorObject) {
                            core.network.dataAtPath("orders/\(order.id)", method: .patch, body: data).then { _ in
                                logInfo("order \(order.id) patch success")
                            }.error { error in
                                logError("error patching order: \(order.id)")
                            }
                        }
                    }
                } else if case KinError.invalidAmount = error {
                    Kin.track { try SpendTransactionBroadcastToBlockchainFailed(errorReason: "\(error)", offerID: offerId, orderID: openOrder?.id ?? "") }
                }
                if  case let EcosystemNetError.service(responseError) = error,
                    let url = responseError.httpResponse?.url,
                    url.pathComponents.contains("offers") {
                    Kin.track { try SpendOrderCreationFailed(errorReason: responseError.message ?? "\(responseError.code)", isNative: false, offerID: offerId, origin: .marketplace) }
                }
                Kin.track { try SpendOrderFailed(errorReason: "\(error)", isNative: false, offerID: offerId, orderID: openOrder?.id ?? "", origin: .marketplace) }
                _ = core.blockchain.balance()
                if let order = openOrder, canCancelOrder {
                    let group = DispatchGroup()
                    group.enter()
                    core.network.delete("orders/\(order.id)").then {
                        logInfo("order canceled: \(order.id)")
                        }.error { error in
                            logError("error canceling order: \(order.id)")
                        }.finally {
                            group.leave()
                    }
                    group.wait()
                }
                openOrder = nil
                if let subp = submissionPromise {
                    subp.signal(FirstSpendError.spendFailed)
                }
                if let sucp = successPromise {
                    sucp.signal(FirstSpendError.spendFailed)
                }
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
                            _ = core.data.changeObjects(of: Order.self,
                                                        changeBlock: { _, orders in
                                if let  completedOrder = orders.first,
                                    completedOrder.orderStatus != .failed {
                                    completedOrder.orderStatus = .completed
                                    if let p = successPromise {
                                        p.signal(completedOrder.id)
                                    }
                                }
                            }, with: NSPredicate(with: ["id": order.id]))
                        }
                        openOrder = nil
                }
                
                if  let prev = prevBalance,
                    let next = core.blockchain.lastBalance,
                    prev.amount != next.amount {
                    Kin.track { try KinBalanceUpdated(previousBalance: (prev.amount as NSDecimalNumber).doubleValue) }
                }
                
        }
        
    }
    
    static func nativeSpend(jwt: String,
                            core: Core) -> Promise<String> {
        let jwtPromise = KinUtil.Promise<String>()
        var jwtConfirmation: String?
        guard let jwtSubmission = try? JSONEncoder().encode(JWTOrderSubmission(jwt: jwt)) else {
            return jwtPromise.signal(EcosystemDataError.encodeError)
        }
        var openOrder: OpenOrder?
        var canCancelOrder = true
        let prevBalance = core.blockchain.lastBalance
        Kin.track { try SpendOrderCreationRequested(isNative: true, offerID: "", origin: .external) }
        core.network.objectAtPath("offers/external/orders",
                                  type: OpenOrder.self,
                                  method: .post,
                                  body: jwtSubmission)
            .then { order -> SDOFlowPromise in
                openOrder = order
                logVerbose("created order \(order.id)")
                Kin.track { try SpendOrderCreationReceived(isNative: true, offerID: order.offer_id, orderID: order.id, origin: .external) }
                guard let recipient = order.blockchain_data?.recipient_address else {
                    return SDOFlowPromise().signal(KinError.internalInconsistency)
                }
                logVerbose("spend offer id \(order.offer_id), recipient \(recipient)")
                return SDOFlowPromise().signal((recipient, Decimal(order.amount), order))
                
            }.then { recipient, amount, order  -> SDOFlowPromise in
                return core.blockchain.balance().then { currentBalance in
                    if (currentBalance as NSDecimalNumber).int32Value < order.amount {
                        return SDOFlowPromise().signal(KinError.insufficientFunds)
                    } else {
                        return SDOFlowPromise().signal((recipient, amount, order))
                    }
                }
            }
            .then { recipient, amount, order -> SDOPFlowPromise in
                guard let appId = core.network.client.authToken?.app_id else {
                    return SDOPFlowPromise().signal(KinEcosystemError.client(.internalInconsistency, nil))
                }
                let memo = PaymentMemoIdentifier(appId: appId,
                                                 id: order.id)
                try core.blockchain.startWatchingForNewPayments(with: memo)
                return core.network.dataAtPath("orders/\(order.id)", method: .post)
                    .then { data in
                        Kin.track { try SpendOrderCompletionSubmitted(isNative: true, offerID: order.offer_id, orderID: order.id, origin: .external) }
                        return core.data.save(Order.self, with: data)
                    }.then {
                        canCancelOrder = false
                        logVerbose("Submitted order \(order.id)")
                        return SDOPFlowPromise().signal((recipient, amount, order, memo))
                }
            }.then { recipient, amount, order, memo -> SDOPFlowPromise in
                return core.data.changeObjects(of: Offer.self,
                                               changeBlock: { _, offers in
                    if let offer = offers.first {
                        offer.pending = true
                        logVerbose("changed offer \(offer.id) status to pending")
                    }
                }, with: NSPredicate(with: ["id" : order.offer_id]))
                    .then {
                        SDOPFlowPromise().signal((recipient, amount, order, memo))
                }
            }.then { recipient, amount, order, memo -> POFlowPromise in
                Kin.track { try SpendTransactionBroadcastToBlockchainSubmitted(offerID: order.offer_id, orderID: order.id) }
                return core.blockchain.pay(to: recipient,
                                           kin: amount,
                                           memo: memo.description)
                    .then { txId in
                        Kin.track { try SpendTransactionBroadcastToBlockchainSucceeded(offerID: order.offer_id, orderID: order.id, transactionID: txId) }
                        logVerbose("\(amount) kin sent to \(recipient)")
                        return POFlowPromise().signal((memo, order))
                }
            }.then { memo, order -> POFlowPromise in
                return core.blockchain.waitForNewPayment(with: memo)
                    .then { txHash in
                        POFlowPromise().signal((memo, order))
                }
            }.then { memo, order -> KinUtil.Promise<OpenOrder> in
                core.blockchain.stopWatchingForNewPayments(with: memo)
                let intervals: [TimeInterval] = [2, 4, 8, 16, 32, 32, 32, 32]
                return KinUtil.attempt(retryIntervals: intervals,
                                       closure: { attemptNumber -> Promise<Void> in
                    let p = KinUtil.Promise<Void>()
                    logVerbose("attempt to get spend order with !pending state (and result): (\(attemptNumber)/\(intervals.count + 1))")
                    var pending = true
                    core.network.dataAtPath("orders/\(order.id)")
                        .then { data in
                            core.data.read(Order.self,
                                           with: data,
                                           readBlock: { networkOrder in
                                jwtConfirmation = (networkOrder.result as? JWTConfirmation)?.jwt
                                let hasResult = jwtConfirmation != nil
                                logVerbose("spend order \(networkOrder.id) status: \(networkOrder.orderStatus), result: \(hasResult ? "👍🏼" : "nil")")
                                if (networkOrder.orderStatus != .pending && hasResult) || networkOrder.orderStatus == .failed {
                                    pending = false
                                }
                            }).then {
                                if pending {
                                    if attemptNumber == 5 || attemptNumber == intervals.count + 1 {
                                        logWarn("attempts reached \(attemptNumber)")
                                        _ = core.data.changeObjects(of: Order.self,
                                                                    changeBlock: { _, orders in
                                            if let order = orders.first {
                                                order.orderStatus = attemptNumber == 5 ? .delayed : .failed
                                            }
                                        }, with: NSPredicate(with: ["id":order.id]))
                                    }
                                    p.signal(OrderStatusError.orderStillPending)
                                } else {
                                    p.signal(())
                                }
                            }
                    }
                    return p
                }).then {
                    KinUtil.Promise<OpenOrder>().signal(order)
                }
                
            }.then { order in
                Kin.track { try SpendOrderCompleted(isNative: true, kinAmount: Double(order.amount), offerID: order.offer_id, orderID: order.id, origin: .external) }
                if let confirmation = jwtConfirmation {
                    jwtPromise.signal(confirmation)
                } else {
                    jwtPromise.signal(OrderStatusError.orderProcessingFailed)
                }
            }
            .error { error in
                logError("\(error)")
                if case KinError.insufficientFunds = error {
                    Kin.track { try SpendTransactionBroadcastToBlockchainFailed(errorReason: "\(error)", offerID: openOrder?.offer_id ?? "", orderID: openOrder?.id ?? "") }
                } else if case let KinError.paymentFailed(payError) = error {
                    Kin.track { try SpendTransactionBroadcastToBlockchainFailed(errorReason: "\(payError)", offerID: openOrder?.offer_id ?? "", orderID: openOrder?.id ?? "") }
                } else if case KinError.invalidAmount = error {
                    Kin.track { try SpendTransactionBroadcastToBlockchainFailed(errorReason: "\(error)", offerID: openOrder?.offer_id ?? "", orderID: openOrder?.id ?? "") }
                }
                
                if  case let EcosystemNetError.service(responseError) = error,
                    let url = responseError.httpResponse?.url,
                    url.pathComponents.contains("external") {
                    Kin.track { try SpendOrderCreationFailed(errorReason: responseError.message ?? "\(responseError.code)", isNative: true, offerID: openOrder?.offer_id ?? "", origin: .external) }
                }
                Kin.track { try SpendOrderFailed(errorReason: "\(error)", isNative: true, offerID: openOrder?.offer_id ?? "", orderID: openOrder?.id ?? "", origin: .external) }
                core.blockchain.stopWatchingForNewPayments()
                _ = core.blockchain.balance()
                if let order = openOrder, canCancelOrder {
                    core.network.delete("orders/\(order.id)")
                        .then {
                            logInfo("order canceled: \(order.id)")
                        }.error { error in
                            logError("error canceling order: \(order.id)")
                        }.finally {
                            jwtPromise.signal(error)
                    }
                } else if case let EcosystemNetError.service(responseError) = error,
                    responseError.code == 4091,
                    let order = (responseError.httpResponse?.allHeaderFields["Location"] as? String)?.split(separator: "/").last {
                    openOrder = nil
                    logInfo("Order already pending or complete: (\(order))")
                    let intervals: [TimeInterval] = [2, 4, 8, 16, 32, 32, 32, 32]
                    _ = KinUtil.attempt(retryIntervals: intervals,
                                        closure: { attemptNumber -> Promise<Void> in
                                            let p = KinUtil.Promise<Void>()
                                            logVerbose("attempt to get spend order with !pending state (and result): (\(attemptNumber)/\(intervals.count + 1))")
                                            var pending = true
                                            
                                            core.network.dataAtPath("orders/\(order)")
                                                .then { data in
                                                    core.data.save(Order.self, with: data)
                                                }.then {
                                                    core.data.queryObjects(of: Order.self, with: NSPredicate(with: ["id":order])) { orders in
                                                        guard let networkOrder = orders.first else {
                                                            p.signal(())
                                                            return
                                                        }
                                                        jwtConfirmation = (networkOrder.result as? JWTConfirmation)?.jwt
                                                        let hasResult = jwtConfirmation != nil
                                                        logVerbose("spend order \(networkOrder.id) status: \(networkOrder.orderStatus), result: \(hasResult ? "👍🏼" : "nil")")
                                                        if (networkOrder.orderStatus != .pending && hasResult) || networkOrder.orderStatus == .failed {
                                                            pending = false
                                                        }
                                                    }.then {
                                                        if pending {
                                                            if attemptNumber == 5 || attemptNumber == intervals.count + 1 {
                                                                logWarn("attempts reached \(attemptNumber)")
                                                                _ = core.data.changeObjects(of: Order.self,
                                                                                            changeBlock: { _, orders in
                                                                                                if let order = orders.first {
                                                                                                    order.orderStatus = attemptNumber == 5 ? .delayed : .failed
                                                                                                }
                                                                }, with: NSPredicate(with: ["id":order]))
                                                            }
                                                            p.signal(OrderStatusError.orderStillPending)
                                                        } else {
                                                            p.signal(())
                                                        }
                                                    }
                                            }.error { error in
                                                 p.signal(())
                                            }
                        return p
                    }).then {
                        if let jwt = jwtConfirmation {
                            jwtPromise.signal(jwt)
                        } else  {
                            jwtPromise.signal(KinEcosystemError.service(.timeout, nil))
                        }
                    }.error { error in
                        jwtPromise.signal(error)
                    }
                } else {
                    openOrder = nil
                    jwtPromise.signal(error)
                }
                
                
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
                            _ = core.data.changeObjects(of: Order.self,
                                                        changeBlock: { _, orders in
                                if let  completedOrder = orders.first,
                                    completedOrder.orderStatus != .failed {
                                    completedOrder.orderStatus = .completed
                                }
                            }, with: NSPredicate(with: ["id": order.id]))
                        }
                        openOrder = nil
                }
                
                if  let prev = prevBalance,
                    let next = core.blockchain.lastBalance,
                    prev.amount != next.amount {
                    Kin.track { try KinBalanceUpdated(previousBalance: (prev.amount as NSDecimalNumber).doubleValue) }
                }
                
        }
        
        return jwtPromise
    }
    
    static func nativeEarn(jwt: String,
                            core: Core) -> Promise<String> {
        let jwtPromise = KinUtil.Promise<String>()
        var jwtConfirmation: String?
        guard let jwtSubmission = try? JSONEncoder().encode(JWTOrderSubmission(jwt: jwt)) else {
            return jwtPromise.signal(EcosystemDataError.encodeError)
        }
        var openOrder: OpenOrder?
        var canCancelOrder = true
        let prevBalance = core.blockchain.lastBalance
        // Todo: can't infer amount and id
        Kin.track { try EarnOrderCreationRequested(kinAmount: 0, offerID: "", offerType: .external) }
        core.network.objectAtPath("offers/external/orders",
                                  type: OpenOrder.self,
                                  method: .post,
                                  body: jwtSubmission)
            .then { order -> SDOFlowPromise in
                openOrder = order
                logVerbose("created order \(order.id)")
                Kin.track { try EarnOrderCreationReceived(offerID: order.offer_id, orderID: order.id) }
                guard let recipient = order.blockchain_data?.recipient_address else {
                    return SDOFlowPromise().signal(KinError.internalInconsistency)
                }
                logVerbose("spend offer id \(order.offer_id), recipient \(recipient)")
                return SDOFlowPromise().signal((recipient, Decimal(order.amount), order))
                
            }.then { recipient, amount, order -> POFlowPromise in
                guard let appId = core.network.client.authToken?.app_id else {
                    return POFlowPromise().signal(KinEcosystemError.client(.internalInconsistency, nil))
                }
                let memo = PaymentMemoIdentifier(appId: appId,
                                                 id: order.id)
                try core.blockchain.startWatchingForNewPayments(with: memo)
                return core.network.dataAtPath("orders/\(order.id)", method: .post)
                    .then { data in
                        Kin.track { try EarnOrderCompletionSubmitted(offerID: order.offer_id, orderID: order.id) }
                        return core.data.save(Order.self, with: data)
                    }.then {
                        canCancelOrder = false
                        logVerbose("Submitted order \(order.id)")
                        return POFlowPromise().signal((memo, order))
                }
            }.then { memo, order -> POFlowPromise in
                return core.blockchain.waitForNewPayment(with: memo)
                    .then { txHash in
                        POFlowPromise().signal((memo, order))
                }
            }.then { memo, order -> KinUtil.Promise<OpenOrder> in
                core.blockchain.stopWatchingForNewPayments(with: memo)
                let intervals: [TimeInterval] = [2, 4, 8, 16, 32, 32, 32, 32]
                return KinUtil.attempt(retryIntervals: intervals,
                                       closure: { attemptNumber -> Promise<Void> in
                                        let p = KinUtil.Promise<Void>()
                                        logVerbose("attempt to get earn order with !pending state (and result): (\(attemptNumber)/\(intervals.count + 1))")
                                        var pending = true
                                        core.network.dataAtPath("orders/\(order.id)")
                                            .then { data in
                                                core.data.read(Order.self,
                                                               with: data,
                                                               readBlock: { networkOrder in
                                                                jwtConfirmation = (networkOrder.result as? JWTConfirmation)?.jwt
                                                                let hasResult = jwtConfirmation != nil
                                                                logVerbose("earn order \(networkOrder.id) status: \(networkOrder.orderStatus), result: \(hasResult ? "👍🏼" : "nil")")
                                                                if (networkOrder.orderStatus != .pending && hasResult) || networkOrder.orderStatus == .failed {
                                                                    pending = false
                                                                }
                                                }).then {
                                                    if pending {
                                                        if attemptNumber == 5 || attemptNumber == intervals.count + 1 {
                                                            logWarn("attempts reached \(attemptNumber)")
                                                            _ = core.data.changeObjects(of: Order.self,
                                                                                        changeBlock: { _, orders in
                                                                                            if let order = orders.first {
                                                                                                order.orderStatus = attemptNumber == 5 ? .delayed : .failed
                                                                                            }
                                                            }, with: NSPredicate(with: ["id":order.id]))
                                                        }
                                                        p.signal(OrderStatusError.orderStillPending)
                                                    } else {
                                                        p.signal(())
                                                    }
                                                }
                                        }
                                        return p
                }).then {
                    KinUtil.Promise<OpenOrder>().signal(order)
                }
                
            }.then { order in
                Kin.track { try EarnOrderCompleted(kinAmount: Double(order.amount), offerID: order.offer_id, offerType: .external, orderID: order.id) }
                if let confirmation = jwtConfirmation {
                    jwtPromise.signal(confirmation)
                } else {
                    jwtPromise.signal(OrderStatusError.orderProcessingFailed)
                }
            }
            .error { error in
                logError("\(error)")
                
                if  case let EcosystemNetError.service(responseError) = error,
                    let url = responseError.httpResponse?.url,
                    url.pathComponents.contains("external") {
                    Kin.track { try EarnOrderCreationFailed(errorReason: responseError.message ?? "\(responseError.code)", offerID: openOrder?.offer_id ?? "") }
                }
                Kin.track { try SpendOrderFailed(errorReason: "\(error)", isNative: true, offerID: openOrder?.offer_id ?? "", orderID: openOrder?.id ?? "", origin: .external)}
                core.blockchain.stopWatchingForNewPayments()
                _ = core.blockchain.balance()
                if let order = openOrder, canCancelOrder {
                    core.network.delete("orders/\(order.id)")
                        .then {
                            logInfo("order canceled: \(order.id)")
                        }.error { error in
                            logError("error canceling order: \(order.id)")
                        }.finally {
                            jwtPromise.signal(error)
                    }
                } else if case let EcosystemNetError.service(responseError) = error,
                    responseError.code == 4091,
                    let order = (responseError.httpResponse?.allHeaderFields["Location"] as? String)?.split(separator: "/").last {
                    openOrder = nil
                    logInfo("Order already pending or complete: (\(order))")
                    let intervals: [TimeInterval] = [2, 4, 8, 16, 32, 32, 32, 32]
                    _ = KinUtil.attempt(retryIntervals: intervals,
                                        closure: { attemptNumber -> Promise<Void> in
                                            let p = KinUtil.Promise<Void>()
                                            logVerbose("attempt to get earn order with !pending state (and result): (\(attemptNumber)/\(intervals.count + 1))")
                                            var pending = true
                                            
                                            core.network.dataAtPath("orders/\(order)")
                                                .then { data in
                                                    core.data.save(Order.self, with: data)
                                                }.then {
                                                    core.data.queryObjects(of: Order.self, with: NSPredicate(with: ["id":order])) { orders in
                                                        guard let networkOrder = orders.first else {
                                                            p.signal(())
                                                            return
                                                        }
                                                        jwtConfirmation = (networkOrder.result as? JWTConfirmation)?.jwt
                                                        let hasResult = jwtConfirmation != nil
                                                        logVerbose("earn order \(networkOrder.id) status: \(networkOrder.orderStatus), result: \(hasResult ? "👍🏼" : "nil")")
                                                        if (networkOrder.orderStatus != .pending && hasResult) || networkOrder.orderStatus == .failed {
                                                            pending = false
                                                        }
                                                        }.then {
                                                            if pending {
                                                                if attemptNumber == 5 || attemptNumber == intervals.count + 1 {
                                                                    logWarn("attempts reached \(attemptNumber)")
                                                                    _ = core.data.changeObjects(of: Order.self,
                                                                                                changeBlock: { _, orders in
                                                                                                    if let order = orders.first {
                                                                                                        order.orderStatus = attemptNumber == 5 ? .delayed : .failed
                                                                                                    }
                                                                    }, with: NSPredicate(with: ["id":order]))
                                                                }
                                                                p.signal(OrderStatusError.orderStillPending)
                                                            } else {
                                                                p.signal(())
                                                            }
                                                    }
                                                }.error { error in
                                                    p.signal(())
                                            }
                                            return p
                    }).then {
                        if let jwt = jwtConfirmation {
                            jwtPromise.signal(jwt)
                        } else  {
                            jwtPromise.signal(KinEcosystemError.service(.timeout, nil))
                        }
                        }.error { error in
                            jwtPromise.signal(error)
                    }
                } else {
                    openOrder = nil
                    jwtPromise.signal(error)
                }
                
                
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
                            _ = core.data.changeObjects(of: Order.self,
                                                        changeBlock: { _, orders in
                                                            if let  completedOrder = orders.first,
                                                                completedOrder.orderStatus != .failed {
                                                                completedOrder.orderStatus = .completed
                                                            }
                            }, with: NSPredicate(with: ["id": order.id]))
                        }
                        openOrder = nil
                }
                
                if  let prev = prevBalance,
                    let next = core.blockchain.lastBalance,
                    prev.amount != next.amount {
                    Kin.track { try KinBalanceUpdated(previousBalance: (prev.amount as NSDecimalNumber).doubleValue) }
                }
                
        }
        
        return jwtPromise
    }
    
}
