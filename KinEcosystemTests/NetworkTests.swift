//
//  NetworkTests.swift
//  KinEcosystemTests
//
//  Created by Elazar Yifrach on 13/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import XCTest
@testable import KinEcosystem

class NetworkTests: XCTestCase {
    
    let mockNet = MockNet(baseURL: URL(string: "http://api.kinmarketplace.com/v1")!)
    let network = EcosystemNet(config: EcosystemConfiguration(baseURL: URL(string: "http://api.kinmarketplace.com/v1")!, apiKey: "apiKey", userId: "userId"))
    var data: EcosystemData!
    
    override func setUp() {
        super.setUp()
        mockNet.start()
        guard   let modelPath = Bundle.ecosystem.path(forResource: "KinEcosystem", ofType: "momd"),
                let store = try? EcosystemData(modelName: "KinEcosystem", modelURL: URL(string: modelPath)!) else { fatalError() }
        data = store
    }
    
    override func tearDown() {
        mockNet.stop()
        let sema = DispatchSemaphore(value: 0)
        data.resetStore().then {
            sema.signal()
            }.error {_ in
                fatalError()
        }
        sema.wait()
        super.tearDown()
    }
    
    func testFetchOffers() {
        
    }
    
}
