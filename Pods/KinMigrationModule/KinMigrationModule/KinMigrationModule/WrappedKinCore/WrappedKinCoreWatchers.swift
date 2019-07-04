//
//  WrappedKinCoreWatchers.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinCoreSDK
import KinUtil

public class WrappedKinCoreBalanceWatch: BalanceWatchProtocol {
    let watch: KinCoreSDK.BalanceWatch

    init(_ watch: KinCoreSDK.BalanceWatch) {
        self.watch = watch
    }

    public var emitter: StatefulObserver<Kin> {
        return watch.emitter
    }
}

public class WrappedKinCorePaymentWatch: PaymentWatchProtocol {
    let watch: KinCoreSDK.PaymentWatch

    init(_ watch: KinCoreSDK.PaymentWatch) {
        self.watch = watch
    }

    public var emitter: Observable<PaymentInfoProtocol> {
        return watch.emitter.map { WrappedKinCorePaymentInfo($0) }
    }

    public var cursor: String? {
        return watch.cursor
    }
}
