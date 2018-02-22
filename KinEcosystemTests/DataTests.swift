//
//  DataTests.swift
//  KinEcosystemTests
//
//  Created by Elazar Yifrach on 13/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import XCTest
@testable import KinEcosystem

class DataTests: BaseDataNetworkTest {
    
    func testStoreOffers() {

        let fetch = self.expectation(description: "")

        network.offers().then { data in
            self.data.syncOffersFromNetworkData(data: data)
            }.then {
                self.data.offers().then { offers in
                    XCTAssert(offers.count > 0)
                    fetch.fulfill()
                }
            }.error { error in
                XCTAssert(false, "\n\(error)\n")
                fetch.fulfill()
        }

        self.wait(for: [fetch], timeout: 5.0)
        
    }
    
    func testDeleteStore() {

        let ex1 = self.expectation(description: "")
        self.data.offers().then { offers in
            XCTAssert(offers.count == 0)
            ex1.fulfill()
        }
        self.wait(for: [ex1], timeout: 5.0)

        let fetch = self.expectation(description: "2")

        network.offers().then { data in
            self.data.syncOffersFromNetworkData(data: data)
            }.then {
                self.data.offers()
            }.then { offers in
                XCTAssert(offers.count > 0)
                return self.data.resetStore()
            }.then {
                self.data.offers()
            }.then { offers in
                XCTAssert(offers.count == 0)
                fetch.fulfill()
            }.error { error in
                XCTAssert(false, "\n\(error)\n")
                fetch.fulfill()
        }

        self.wait(for: [fetch], timeout: 5.0)

    }
    
}
