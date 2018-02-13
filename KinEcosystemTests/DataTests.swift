//
//  DataTests.swift
//  KinEcosystemTests
//
//  Created by Elazar Yifrach on 13/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import XCTest
@testable import KinEcosystem

class DataTests: XCTestCase {
    
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
        let sema = DispatchSemaphore(value: 1)
        DispatchQueue.global().async {
            self.data.resetStore().then {
                sema.signal()
                }.error {_ in
                    fatalError()
            }
        }
        sema.wait()
        super.tearDown()
    }
    
    func testStoreOffers() {

        let fetch = self.expectation(description: "")
        mockNet.stubRequest("offers", method: .GET, statusCode: 200, responseFilename: "10_ok_offers")

        network.offers().then { data in
            self.data.syncOffersFromNetworkData(data: data)
            }.then {
                self.data.offers().then { offers in
                    XCTAssert(offers.count == 10)
                    fetch.fulfill()
                }
            }.error { _ in
                XCTAssert(false)
                fetch.fulfill()
        }

        self.wait(for: [fetch], timeout: 1.0)
        
    }
    
    func testDeleteStore() {

        let ex1 = self.expectation(description: "")
        self.data.offers().then { offers in
            XCTAssert(offers.count == 0)
            ex1.fulfill()
        }
        self.wait(for: [ex1], timeout: 1.0)

        let fetch = self.expectation(description: "2")
        mockNet.stubRequest("offers", method: .GET, statusCode: 200, responseFilename: "10_ok_offers")

        network.offers().then { data in
            self.data.syncOffersFromNetworkData(data: data)
            }.then {
                self.data.offers()
            }.then { offers in
                XCTAssert(offers.count == 10)
                return self.data.resetStore()
            }.then {
                self.data.offers()
            }.then { offers in
                XCTAssert(offers.count == 0)
                fetch.fulfill()
            }.error { _ in
                fetch.fulfill()
        }

        self.wait(for: [fetch], timeout: 1.0)

    }
    
}
