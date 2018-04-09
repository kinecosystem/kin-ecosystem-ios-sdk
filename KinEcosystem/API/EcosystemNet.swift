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
import KinUtil

struct EcosystemConfiguration {
    var baseURL: URL
    var apiKey: String
    var appId: String
    var userId: String
    var jwt: String?
    var publicAddress: String
}

class EcosystemNet {
    
    var client: RestClient!
    var tosAccepted: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "tosAccepted")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "tosAccepted")
        }
    }
    init(config: EcosystemConfiguration) {
        client = RestClient(config)
        if Kin.shared.needsReset {
            tosAccepted = false
            client.authToken = nil
        }
    }
    
    @discardableResult
    func authorize() -> Promise<Void> {
        let p = Promise<Void>()
        if client.authToken != nil {
            return p.signal(())
        }
        guard let data = try? JSONEncoder().encode(client.signInData) else {
            return p.signal(EcosystemNetError.requestBuild)
        }
        logInfo("sign data: \(String(data: data, encoding: .utf8)!)")
        client.buildRequest(path: "users", method: .post, body: data)
            .then { request in
                self.client.dataRequest(request)
            }.then { data in
                guard let token = try? JSONDecoder().decode(AuthToken.self, from: data) else {
                    p.signal(EcosystemNetError.responseParse)
                    return
                }
                self.client.authToken = token
                p.signal(())
            }.error { error in
                p.signal(error)
        }
        return p
    }
    
    func acceptTOS() -> Promise<Void> {
        let p = Promise<Void>()
        guard tosAccepted == false else {
            return p.signal(())
        }
        authorize().then {
                self.client.buildRequest(path: "users/me/activate", method: .post)
            }.then { request in
                self.client.dataRequest(request)
            }.then { data in
                guard let token = try? JSONDecoder().decode(AuthToken.self, from: data) else {
                    p.signal(EcosystemNetError.responseParse)
                    return
                }
                guard token.activated else {
                    p.signal(EcosystemNetError.server("server returned non active token"))
                    return
                }
                self.tosAccepted = true
                self.client.authToken = token
                p.signal(())
            }.error { error in
                p.signal(error)
        }
        return p
    }
    
    func dataAtPath(_ path: String,
                    method: HTTPMethod = .get,
                    contentType: ContentType = .json,
                    body: Data? = nil,
                    parameters: [String: String]? = nil) -> Promise<Data> {
        return authorize().then {
                self.client.buildRequest(path: path, method: method, body: body, parameters: parameters)
            }.then { request in
                self.client.dataRequest(request)
            }
    }
    
    func objectAtPath<T: Decodable>(_ path: String,
                                    type: T.Type,
                                    method: HTTPMethod = .get,
                                    contentType: ContentType = .json,
                                    body: Data? = nil,
                                    parameters: [String: String]? = nil) -> Promise<T> {
        let p = Promise<T>()
        dataAtPath(path, method: method).then { data in
            return p.signal(try JSONDecoder().decode(type, from: data))
        }
        return p
    }
    
    func delete(_ path: String, parameters: [String: String]? = nil) -> Promise<Void> {
        return authorize().then {
            self.client.buildRequest(path: path, method: .delete, parameters: parameters)
            }.then { request in
                self.client.request(request)
        }
    }
    
}
