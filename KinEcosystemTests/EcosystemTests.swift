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
import CoreData
import CoreDataStack
@testable import KinSDK

@testable import KinEcosystem

class EcosystemTests: XCTestCase {
    
    let mockNet = MockNet(baseURL: URL(string: "http://api.kinmarketplace.com/v1")!)
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testStartKin() {
        
        let start = self.expectation(description: "")
        Kin.shared.start(apiKey: "a", userId: "b")
        XCTAssert(Kin.shared.started)
        let balanceExp = self.expectation(description: "")
        Kin.shared.balance { balance in
            print("balance: \(balance)")
            balanceExp.fulfill()
        }
        self.wait(for: [balanceExp], timeout: 30.0)
        
        mockNet.start()
        mockNet.stubRequest("offers", method: .GET, statusCode: 200, responseFilename: "10_ok_offers")
        
        Kin.shared.updateOffers().then {
            Kin.shared.data.offers()
            }.then { offers in
                XCTAssert(offers.count == 10)
                start.fulfill()
            }.error { error in
                XCTAssert(false)
                start.fulfill()
        }
        
        self.wait(for: [start], timeout: 1.0)
        mockNet.stop()
    }
    
}
