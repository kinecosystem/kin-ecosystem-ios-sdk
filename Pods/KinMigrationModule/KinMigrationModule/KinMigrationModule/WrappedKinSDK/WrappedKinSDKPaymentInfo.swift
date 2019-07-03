//
//  WrappedKinSDKPaymentInfo.swift
//  multi
//
//  Created by Corey Werner on 07/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinSDK

public class WrappedKinSDKPaymentInfo: PaymentInfoProtocol {
    let paymentInfo: KinSDK.PaymentInfo

    init (_ paymentInfo: KinSDK.PaymentInfo) {
        self.paymentInfo = paymentInfo
    }

    public var createdAt: Date {
        return paymentInfo.createdAt
    }

    public var credit: Bool {
        return paymentInfo.credit
    }

    public var debit: Bool {
        return paymentInfo.debit
    }

    public var source: String {
        return paymentInfo.source
    }

    public var hash: String {
        return paymentInfo.hash
    }

    public var amount: Kin {
        return paymentInfo.amount / Decimal(kinSDKAssetUnitDivisor)
    }

    public var destination: String {
        return paymentInfo.destination
    }

    public var memoText: String? {
        return paymentInfo.memoText
    }

    public var memoData: Data? {
        return paymentInfo.memoData
    }
}
