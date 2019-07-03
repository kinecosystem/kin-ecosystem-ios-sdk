//
//  Watchers.swift
//  KinSDK
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

/**
 `PaymentWatch` watches for `PaymentInfo` changes of a given account and sends the new `PaymentInfo` value when one is available.
 Refer to `KinAccount.watchPayments`.
 */
public class PaymentWatch {
    private let txWatch: EventWatcher<TxEvent>
    private let linkBag = LinkBag()

    /**
     The `Observable` that will be signalled when a new `PaymentInfo` value is available.
     */
    public let emitter: Observable<PaymentInfo>

    /**
     The id of the last payment info after which we want to be signalled of new payments.
     */
    public var cursor: String? {
        return txWatch.eventSource.lastEventId
    }

    init(node: Stellar.Node, account: String, cursor: String? = nil) {
        self.txWatch = Stellar.txWatch(account: account, lastEventId: cursor, node: node)

        self.emitter = self.txWatch.emitter
            .filter({ ti in
                ti.payments.count > 0
            })
            .map({
                return PaymentInfo(txEvent: $0, account: account)
            })

        self.emitter.add(to: linkBag)
    }
}

/**
 `BalanceWatch` watches for `Kin` balance changes of a given account and sends the new `Kin` value when one is available.
 Refer to `KinAccount.watchBalance`.

 ```
 if let balanceWatcher = try? account.watchBalance(nil) {
    balanceWatcher.emitter.on { (balance: Kin) in
        print("The account's balance has changed: \(balance) Kin")
    }
 }
 ```
 */
public class BalanceWatch {
    private let txWatch: EventWatcher<TxEvent>
    private let linkBag = LinkBag()

    /**
     The `StatefulObserver` that will be signalled when a new `Kin` value is available.
    */
    public let emitter: StatefulObserver<Kin>

    init(node: Stellar.Node, account: String, balance: Kin? = nil) {
        var balance = balance ?? Decimal(0)

        self.txWatch = Stellar.txWatch(account: account, lastEventId: "now", node: node)

        self.emitter = txWatch.emitter
            .map({ txEvent in
                if case let TransactionMeta.operations(opsMeta) = txEvent.meta {
                    for op in opsMeta {
                        for change in op.changes {
                            switch change {
                            case .LEDGER_ENTRY_CREATED(let le),
                                 .LEDGER_ENTRY_UPDATED(let le):
                                if case let LedgerEntry.Data.TRUSTLINE(trustlineEntry) = le.data {
                                    if trustlineEntry.account == account {
                                        balance = Decimal(Double(trustlineEntry.balance) / Double(AssetUnitDivisor))
                                        return balance
                                    }
                                }
                                else if case let LedgerEntry.Data.ACCOUNT(accountEntry) = le.data {
                                    if accountEntry.accountID.publicKey == account {
                                        balance = Decimal(Double(accountEntry.balance) / Double(AssetUnitDivisor))
                                        return balance
                                    }
                                }
                            case .LEDGER_ENTRY_STATE,
                                 .LEDGER_ENTRY_REMOVED:
                                break
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

/**
 `CreationWatch` notifies when we know that the status of an account is `.created`. An event is sent when an account has just been created on the blockchain network, or when we start watching an account that is already created.
 */
public class CreationWatch {
    private let paymentWatch: EventWatcher<PaymentEvent>
    private let linkBag = LinkBag()

    /**
     The `Observable` that will be signalled when the account is created.
     */
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

