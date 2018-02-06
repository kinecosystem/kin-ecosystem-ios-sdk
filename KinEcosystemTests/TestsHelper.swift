//
//
//  TestsHelper.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//


import Foundation
@testable import KinEcosystem

class TestsHelper {
    
    static func stubAllTheNetworks() {
        let baseURL = URL(string: "http://api.kinmarketplace.com/v1")!
        var stub = StubRequest(method: .GET, url: baseURL.appendingPathComponent("offers"))
        var response = StubResponse(statusCode: 200)
        response.body = try! Data(contentsOf: Bundle(for: TestsHelper.self).url(forResource: "10_ok_offers", withExtension: "json")!)
        stub.response = response
        Hippolyte.shared.add(stubbedRequest: stub)
        Hippolyte.shared.start()
    }
    
    static func unstubAllTheNetworks() {
        Hippolyte.shared.stop()
    }
}

struct ESConfigProduction: EcosystemConfiguration {
    let baseURL = URL(string: "http://api.kinmarketplace.com/v1")!
}




