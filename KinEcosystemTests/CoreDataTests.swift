//
//
//  CoreDataTests.swift
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
    
    func testSimpleInsertion() {
        
        mockNet.stub("offers", method: .GET, statusCode: 200, responseFilename: "10_ok_offers")
        
        let getOffers = self.expectation(description: "get data, parse and persist")
        
        DispatchQueue.global().async {
            self.ecosystem.updateOffers().then {
                getOffers.fulfill()
                }.error { error in
                    XCTAssert(false, error.localizedDescription)
                    getOffers.fulfill()
            }
        }
        
        self.wait(for: [getOffers], timeout: 10.0)
        
        let query = self.expectation(description: "coredata query")
        
        self.ecosystem.dataStore.stack.query { context in
            let request = NSFetchRequest<Offer>(entityName: "Offer")
            let diskOffers = try! context.fetch(request)
            XCTAssert(diskOffers.count == 10)
            query.fulfill()
        }
        
        self.wait(for: [query], timeout: 10.0)
        
    }
    
}
