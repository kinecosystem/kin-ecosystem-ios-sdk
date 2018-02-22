//
//
//  EcosystemNet.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//


import Foundation

struct EcosystemConfiguration {
    var baseURL: URL
    var apiKey: String
    var userId: String
    var jwt: String?
    var publicAddress: String
}

class EcosystemNet {
    
    var client: RestClient!
    
    init(config: EcosystemConfiguration) {
        client = RestClient(config)
    }
    
    @discardableResult
    func authorize() -> Promise<Void> {
        let p = Promise<Void>()
        if client.authToken != nil {
            return p.signal(())
        }
        logInfo(String(describing: client.signInData))
        guard let data = try? JSONEncoder().encode(client.signInData) else {
            return p.signal(EcosystemNetError.requestBuild)
        }
        client.buildRequest(path: "users", method: .post, body: data)
            .then { request in
                self.client.dataRequest(request)
            }.then { data in
                guard let token = try? JSONDecoder().decode(AuthToken.self, from: data) else {
                    p.signal(EcosystemNetError.responseParseError)
                    return
                }
                self.client.authToken = token
                p.signal(())
            }.error { error in
                p.signal(error)
        }
        return p
    }
    
    func offers() -> Promise<Data> {
        let p = Promise<Data>()
        authorize().then {
                self.client.buildRequest(path: "offers", method: .get)
            }.then { request in
                self.client.dataRequest(request)
            }.then { data in
                p.signal(data)
            }.error { error in
                p.signal(error)
        }
        return p
    }
    
    func orders() -> Promise<Data> {
        let p = Promise<Data>()
        authorize().then {
                self.client.buildRequest(path: "orders", method: .get)
            }.then { request in
                self.client.dataRequest(request)
            }.then { data in
                p.signal(data)
            }.error { error in
                p.signal(error)
        }
        return p
    }
    
    
    
}
