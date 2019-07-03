//
//  Watchers.swift
//  KinCoreSDK
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit
import KinUtil

public class PaymentWatch {
    private let txWatch: EventWatcher<TxEvent>
    private let linkBag = LinkBag()

    public let emitter: Observable<PaymentInfo>

    public var cursor: String? {
        return txWatch.eventSource.lastEventId
    }

    init(node: Stellar.Node, account: String, asset: Asset, cursor: String? = nil) {
        self.txWatch = Stellar.txWatch(account: account, lastEventId: cursor, node: node)

        self.emitter = self.txWatch.emitter
            .filter({ ti in
                ti.payments.count > 0 && ti.payments
                    .filter({ $0.asset == asset }).count > 0
            })
            .map({ return PaymentInfo(txEvent: $0, account: account, asset: asset) })

        self.emitter.add(to: linkBag)
    }
}

public class BalanceWatch {
    private let txWatch: EventWatcher<TxEvent>
    private let linkBag = LinkBag()

    public let emitter: StatefulObserver<Decimal>

    init(node: Stellar.Node, account: String, balance: Decimal? = nil, asset: Asset) {
        var balance = balance ?? Decimal(0)

        self.txWatch = Stellar.txWatch(account: account, lastEventId: "now", node: node)

        self.emitter = txWatch.emitter
            .map({ txEvent in
                if case let TransactionMeta.operations(opsMeta) = txEvent.meta {
                    for op in opsMeta {
                        for change in op.changes {
                            switch change {
                            case .LEDGER_ENTRY_CREATED: break
                            case .LEDGER_ENTRY_REMOVED: break
                            case .LEDGER_ENTRY_UPDATED(let le):
                                if case let LedgerEntry.Data.TRUSTLINE(trustlineEntry) = le.data {
                                    if trustlineEntry.account == account && trustlineEntry.asset == asset {
                                        balance = Decimal(Double(trustlineEntry.balance) / Double(KinMultiplier))
                                        return balance
                                    }
                                }
                            case .LEDGER_ENTRY_STATE: break
                            }
                        }
                    }
                }

                return balance
            })
            .stateful()

        self.emitter.add(to: linkBag)

        if balance > 0 {
            self.emitter.next(balance)
        }
    }
}

public class CreationWatch {
    private let paymentWatch: EventWatcher<PaymentEvent>
    private let linkBag = LinkBag()

    public let emitter: Observable<Bool>

    init(node: Stellar.Node, account: String) {
        self.paymentWatch = Stellar.paymentWatch(account: account, lastEventId: nil, node: node)

        self.emitter = paymentWatch.emitter
            .map({ _ in
                return true
            })

        self.emitter.add(to: linkBag)
    }
}

