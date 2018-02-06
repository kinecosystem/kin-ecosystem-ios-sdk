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

@testable import KinEcosystem



class CoreDataTests: XCTestCase {
    
    var ecosystem:Ecosystem!
    
    override func setUp() {
        super.setUp()
        let net = EcosystemNet(config: ESConfigProduction())
        guard let modelPath = Bundle.ecosystem.path(forResource: "KinEcosystem", ofType: "momd") else { fatalError() }
        guard let dataStore = try? EcosystemData(modelName: "KinEcosystem", modelURL: URL(string: modelPath)!, storeType: NSInMemoryStoreType) else { fatalError() }
        ecosystem = Ecosystem(network: net, dataStore: dataStore)
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func testSimpleInsertion() {
        
        let exc = self.expectation(description: "waiting for promise")
        ecosystem.updateOffers().then {
            exc.fulfill()
            }.error { error in
                XCTAssert(false, error.localizedDescription)
                exc.fulfill()
        }
        self.wait(for: [exc], timeout: 30.0)
    }
    
}
