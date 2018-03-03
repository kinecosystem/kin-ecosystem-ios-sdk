//
//  BaseDataNetworkTest.swift
//  KinEcosystemTests
//
//  Created by Elazar Yifrach on 13/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import XCTest
@testable import KinEcosystem

class BaseDataNetworkTest: XCTestCase {
    
    let network = EcosystemNet(config: EcosystemConfiguration(baseURL: URL(string: "http://localhost:3000/v1")!,
                                                              apiKey: "apiKey",
                                                              appId: "kik",
                                                              userId: "doody",
                                                              jwt: nil,
                                                              publicAddress: "ABCDEFGGG9837645998h"))
    var data: EcosystemData!
    
    override func setUp() {
        super.setUp()
        guard   let modelPath = Bundle.ecosystem.path(forResource: "KinEcosystem", ofType: "momd"),
                let store = try? EcosystemData(modelName: "KinEcosystem", modelURL: URL(string: modelPath)!) else { fatalError() }
        data = store
    }
    
    override func tearDown() {
        let sema = DispatchSemaphore(value: 1)
        data.resetStore().then {
            sema.signal()
            }.error {_ in
                fatalError()
        }
        sema.wait()
        super.tearDown()
    }
    
    
    
}
