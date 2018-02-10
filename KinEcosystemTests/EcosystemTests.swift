//
//
//  EcosystemTests.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//


import XCTest

@testable import KinEcosystem

class EcosystemTests: XCTestCase {
    
    var ecosystem:Ecosystem!
    let mockNet = MockNet(baseURL: URL(string: "http://api.kinmarketplace.com/v1")!)
    
    override func setUp() {
        super.setUp()
        mockNet.start()
        let net = EcosystemNet(config: ESConfigProduction())
        ecosystem = Ecosystem(network: net)
    }
    
    override func tearDown() {
        super.tearDown()
        mockNet.stop()
    }
 
    func testUpdateOffers() {
        
        mockNet.stubRequest("offers", method: .GET, statusCode: 200, responseFilename: "10_ok_offers")
        
        let updateOffers = self.expectation(description: "get data, parse and persist")
        
        self.ecosystem.updateOffers().then {
            XCTAssert(self.ecosystem.offersViewModel?.count == 10)
            XCTAssert(self.ecosystem.offers?.count == 10)
            for index in 0..<10 {
                XCTAssert(self.ecosystem.offersViewModel?[index].id == self.ecosystem.offersViewModel?[index].id)
            }
            updateOffers.fulfill()
            }.error { error in
                XCTAssert(false)
                updateOffers.fulfill()
        }
        self.wait(for: [updateOffers], timeout: 1.0)
    }
    
}
