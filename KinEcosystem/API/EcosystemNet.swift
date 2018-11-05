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
    var apiKey: String?
    var appId: String?
    var userId: String?
    var jwt: String?
    var publicAddress: String
}

@available(iOS 9.0, *)
class EcosystemNet {
    
    var client: RestClient!
    
    init(config: EcosystemConfiguration) {
        client = RestClient(config)
        if Kin.shared.needsReset {
            client.authToken = nil
        }
    }
    
    @discardableResult
    func authorize() -> Promise<AuthToken> {
        let p = Promise<AuthToken>()
        if let auth = client.authToken {
            return p.signal(auth)
        }
        guard let data = try? JSONEncoder().encode(client.signInData) else {
            return p.signal(EcosystemNetError.requestBuild)
        }
        logVerbose("sign data: \(String(data: data, encoding: .utf8)!)")
        client.buildRequest(path: "users", method: .post, body: data)
            .then { request in
                self.client.dataRequest(request)
            }.then { data in
                guard let token = try? JSONDecoder().decode(AuthToken.self, from: data) else {
                    p.signal(EcosystemNetError.responseParse)
                    return
                }
                self.client.authToken = token
                p.signal(token)
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
        return authorize().then {_ in
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
        dataAtPath(path, method: method, body: body).then { data in
            guard let object = try? JSONDecoder().decode(type, from: data) else {
                p.signal(EcosystemDataError.decodeError)
                return
            }
            p.signal(object)
        }.error { error in
            p.signal(error)
        }
        return p
    }
    
    func delete(_ path: String, parameters: [String: String]? = nil) -> Promise<Void> {
        return authorize().then { _ in
            self.client.buildRequest(path: path, method: .delete, parameters: parameters)
            }.then { request in
                self.client.request(request)
        }
    }
    
}
