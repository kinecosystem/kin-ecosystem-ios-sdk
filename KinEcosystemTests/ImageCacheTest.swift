//
//
//  ImageCacheTest.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//


import XCTest
@testable import KinEcosystem

class ImageCacheTest: XCTestCase {
    
    var ecosystem:Ecosystem!
    let mockNet = MockNet(baseURL: URL(string: "http://api.kinmarketplace.com/v1")!)
    
    override func setUp() {
        super.setUp()
        mockNet.start()
    }
    
    override func tearDown() {
        super.tearDown()
        mockNet.stop()
    }
    
    func testImageCache() {
        
        mockNet.stubImage("kid.png", imageBundleURL: Bundle(for: ImageCacheTest.self).url(forResource: "kid", withExtension: "png")!)
        let imageURL = mockNet.baseURL.appendingPathComponent("kid.png")
        
        let imageWait1 = self.expectation(description: "image")
        ImageCache.shared.image(for: imageURL).then { result in
            XCTAssert(result.cached == false)
            imageWait1.fulfill()
            }.error { error in
                XCTAssert(false)
                imageWait1.fulfill()
        }
        self.wait(for: [imageWait1], timeout: 5.0)
        let imageWait2 = self.expectation(description: "image")
        ImageCache.shared.image(for: imageURL).then { result in
            XCTAssert(result.cached == true)
            imageWait2.fulfill()
            }.error { error in
                XCTAssert(false)
                imageWait2.fulfill()
        }
        self.wait(for: [imageWait2], timeout: 5.0)
    }
    
}
