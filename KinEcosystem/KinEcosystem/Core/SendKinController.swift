//
//  SendKinController.swift
//  KinEcosystem
//
//  Created by Natan Rolnik on 21/07/19.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import Foundation
import KinUtil
import SendKin

class SendKinController {
    let core: Core

    init(core: Core) {
        self.core = core
    }
}

extension SendKinController: SendKinFlowDelegate {
    public func sendKin(amount: UInt64, to receiverAddress: String, receiverApp: App, memo: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard core.blockchain.migrationManager?.version == .kinSDK else {
            completion(.failure(KinEcosystemError.client(.internalInconsistency, nil)))
            return
        }

        let core = self.core
        let memoId = PaymentMemoIdentifier.components(appId: kinAppId, id: memo)
        var orderId = ""
        var orderData: Data!

        let transferOrder = OutgoingTransfer(amount: amount,
                                             appId: receiverApp.memo,
                                             description: "Transferred on",
                                             memo: memo,
                                             title: "Transfer to \(receiverApp.name)",
            walletAddress: receiverAddress)
        core.network.createTransferOrder(with: transferOrder)
            .then { order -> Promise<Data> in
                orderId = order.id
                return core.blockchain.generateTransactionData(to: receiverAddress,
                                                               kin: Decimal(amount),
                                                               memo: memo,
                                                               fee: 0)
            }.then { txData -> Promise<Data> in
                try? core.blockchain.startWatchingForNewPayments(with: memoId)
                return core.network.dataAtPath("orders/\(orderId)", method: .post, body: txData)
            }
            .then { order -> Promise<String?> in
                orderData = order
                return core.blockchain.waitForNewPayment(with: memoId, timeout: 15.0, policy: .ignore)
            }
            .then { _ in core.data.save(Order.self, with: orderData) }
            .then { completion(.success(())) }
            .error { completion(.failure($0)) }
    }

    public var balance: UInt64 {
        guard let lastBalance = core.blockchain.lastBalance else {
            return 0
        }

        return (lastBalance.amount as NSDecimalNumber).uint64Value
    }

    public var kinAppId: String {
        return core.jwt?.appId ?? ""
    }
}

extension SendKinController: ReceiveKinFlowDelegate {
    public func handlePossibleIncomingTransaction(senderAppName: String, senderAppId: String, memo: String) {
        let transfer = IncomingTransfer(appId: senderAppId, description: "From \(senderAppName)", memo: memo, title: "Receive Kin")
        try? core.network.createIncomingOrder(with: transfer)
    }

    public func provideUserAddress(addressHandler: @escaping (String?) -> Void) {
        addressHandler(core.blockchain.account?.publicAddress ?? nil)
    }
}

