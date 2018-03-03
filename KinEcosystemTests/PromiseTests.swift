//
//  PromiseTests.swift
//  KinEcosystemTests
//
//  Created by Elazar Yifrach on 13/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import XCTest
@testable import KinEcosystem
@testable import KinUtil

class PromiseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func givePromiseBool() -> Promise<Void> {
        let p = Promise<Void>()
        return p.signal(())
    }
    
    func testQueue() {
        givePromiseBool().then(on: DispatchQueue.global()) {
            XCTAssert(Thread.isMainThread == false)
        }.then(on: DispatchQueue.main) {
            XCTAssert(Thread.isMainThread == true)
        }
    }
    
   
    
}
