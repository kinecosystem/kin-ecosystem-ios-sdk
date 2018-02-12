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

@testable import KinEcosystem

class EcosystemTests: XCTestCase {
    
    let mockNet = MockNet(baseURL: URL(string: "http://api.kinmarketplace.com/v1")!)
    
    override func setUp() {
        super.setUp()
        mockNet.start()
    }
    
    override func tearDown() {
        super.tearDown()
        mockNet.stop()
    }
    
    func testStartKin() {
        mockNet.stubRequest("offers", method: .GET, statusCode: 200, responseFilename: "10_ok_offers")
        let start = self.expectation(description: "")
        Kin.shared.start(apiKey: "a", userId: "b")
        XCTAssert(Kin.shared.started)
        Kin.shared.updateOffers().then {
            Kin.shared.generateViewModel().then { offerViewModels in
                XCTAssert(offerViewModels.count == 10)
                start.fulfill()
            }
            }.error { error in
                XCTAssert(false)
                start.fulfill()
        }
        self.wait(for: [start], timeout: 1.0)
    }
    
}
