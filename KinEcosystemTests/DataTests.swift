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

        network.dataAtPath("offers").then { data in
                self.data.sync(OffersList.self, with: data)
            }.then {
                self.data.objects(of: Offer.self)
            }.then { offers in
                XCTAssert(offers.count > 0)
                fetch.fulfill()
            }.error { error in
                XCTAssert(false, String(describing: error))
                fetch.fulfill()
        }
        
        self.wait(for: [fetch], timeout: 5.0)
        
    }
    
    func testStoreOrders() {
        
        let fetch = self.expectation(description: "")
        
        network.dataAtPath("orders").then { data in
                self.data.sync(OrdersList.self, with: data)
            }.then {
                self.data.objects(of: Order.self)
            }.then { orders in
                XCTAssert(orders.count > 0)
                fetch.fulfill()
            }.error { error in
                XCTAssert(false, String(describing: error))
                fetch.fulfill()
        }
        
        self.wait(for: [fetch], timeout: 5.0)
        
    }
    
    
}
