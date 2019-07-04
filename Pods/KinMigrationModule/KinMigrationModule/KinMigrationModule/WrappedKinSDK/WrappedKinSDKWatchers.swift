//
//  WrappedKinSDKWatchers.swift
//  multi
//
//  Created by Corey Werner on 06/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinSDK
import KinUtil

public class WrappedKinSDKBalanceWatch: BalanceWatchProtocol {
    let watch: KinSDK.BalanceWatch

    init(_ watch: KinSDK.BalanceWatch) {
        self.watch = watch
    }

    public var emitter: StatefulObserver<Kin> {
        return watch.emitter
    }
}

public class WrappedKinSDKPaymentWatch: PaymentWatchProtocol {
    let watch: KinSDK.PaymentWatch

    init(_ watch: KinSDK.PaymentWatch) {
        self.watch = watch
    }

    public var emitter: Observable<PaymentInfoProtocol> {
        return watch.emitter.map { WrappedKinSDKPaymentInfo($0) }
    }

    public var cursor: String? {
        return watch.cursor
    }
}
