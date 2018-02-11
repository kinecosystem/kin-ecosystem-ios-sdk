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



class CoreDataTests: XCTestCase {
    
    var ecosystem:Ecosystem!
    let mockNet = MockNet(baseURL: URL(string: "http://api.kinmarketplace.com/v1")!)
    
    override func setUp() {
        super.setUp()
        mockNet.start()
        let net = EcosystemNet(config: ESConfigProduction())
        guard let modelPath = Bundle.ecosystem.path(forResource: "KinEcosystem", ofType: "momd") else { fatalError() }
        guard let dataStore = try? EcosystemData(modelName: "KinEcosystem", modelURL: URL(string: modelPath)!, storeType: NSInMemoryStoreType) else { fatalError() }
        ecosystem = Ecosystem(network: net, dataStore: dataStore)
    }
    
    override func tearDown() {
        super.tearDown()
        mockNet.stop()
    }
 
    func testUpdateOffers() {
        
        mockNet.stubRequest("offers", method: .GET, statusCode: 200, responseFilename: "10_ok_offers")
        
        let updateOffers = self.expectation(description: "get data, parse and persist")
        
        self.ecosystem.updateOffers().then {
            XCTAssert(self.ecosystem.offersViewModel?.offers.count == 10)
            self.ecosystem.dataStore.stack.query { context in
                let request = NSFetchRequest<Offer>(entityName: "Offer")
                let diskOffers = try! context.fetch(request)
                XCTAssert(diskOffers.count == 10)
                updateOffers.fulfill()
                }
            }.error { error in
                XCTAssert(false, error.localizedDescription)
        }
        
        self.wait(for: [updateOffers], timeout: 1.0)
        
    }
    
}
