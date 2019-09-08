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
}

class EcosystemNet {
    
    var client: RestClient!
    private var authPromise = Promise<(AuthToken, String?)>()
    private var authLock: Int = 1
    fileprivate var authorized: Bool {
        get {
            var result: Bool!
            synced(authLock) {
                result = client.authToken != nil
            }
            return result
        }
    }
    private(set) var authInFlight = false
    private var isAuthorizing: Bool {
        get {
            var result: Bool!
            synced(self) {
                result = authInFlight
            }
            return result
        }
        set {
            synced(self) {
                authInFlight = newValue
            }
        }
    }
    
    init(config: EcosystemConfiguration) {
        client = RestClient(config)
    }
    
    @discardableResult
    func authorize(jwt: String, lastKnownWalletAddress: String?) -> Promise<(AuthToken, String?)> {
        
        if authorized && lastKnownWalletAddress != nil {
            return Promise<(AuthToken, String?)>().signal((client.authToken!, nil))
        }
        
        let sign = SignInData(jwt: jwt, sign_in_type: SignInType.jwt.rawValue)
        guard let data = try? JSONEncoder().encode(sign) else {
            return Promise<(AuthToken, String?)>().signal(EcosystemNetError.requestBuild)
        }
        
        if isAuthorizing {
            return authPromise
        }
        
        authPromise = Promise<(AuthToken, String?)>()
        isAuthorizing = true
        
        client.buildRequest(path: "users", method: .post, body: data)
            .then { request in
                self.client.dataRequest(request)
            }.then { data in
                guard let response = try? JSONDecoder().decode(RegisterResponse.self, from: data) else {
                    self.authPromise.signal(EcosystemNetError.responseParse)
                    return
                }
                self.client.authToken = response.auth
                self.authPromise.signal((response.auth, response.user.currentWallet))
            }.error { error in
                self.authPromise.signal(error)
            }.finally {
                self.isAuthorizing = false
        }
        
        return authPromise
    }
    
    func unAuthorize() -> Promise<Void>  {
        guard client.authToken != nil else {
            return Promise<Void>().signal(())
        }
        let p = Promise<Void>()
        Kin.track { try UserLogoutRequested() }
        client.buildRequest(path: "users/me/session", method: .delete)
        .then { request in
            self.client.request(request)
        }.then {
            logInfo("logged out")
        }.error { error in
            logError("error logging out: \(error)")
        }.finally {
            self.client.authToken = nil
            p.signal(())
        }
        return p
    }
    
    func dataAtPath(_ path: String,
                    method: HTTPMethod = .get,
                    contentType: ContentType = .json,
                    body: Data? = nil,
                    parameters: [String: String]? = nil) -> Promise<Data> {
        guard client.authToken != nil else {
            return Promise<Data>().signal(KinEcosystemError.service(.notLoggedIn, nil))
        }
        return client.buildRequest(path: path, method: method, body: body, parameters: parameters)
            .then { request in
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
            do {
                let object = try JSONDecoder().decode(type, from: data)
                p.signal(object)
            } catch {
                p.signal(error)
            }
        }.error { error in
            p.signal(error)
        }
        return p
    }
    
    func delete(_ path: String, parameters: [String: String]? = nil) -> Promise<Void> {
        guard client.authToken != nil else {
            return Promise<Void>().signal(KinEcosystemError.service(.notLoggedIn, nil))
        }
        return client.buildRequest(path: path, method: .delete, parameters: parameters)
            .then { request in
                self.client.request(request)
        }
    }

    @discardableResult
    func isMigrationAllowed(appId:String,publicAddress:String) -> Promise<Bool> {
        return client.buildRequest(path: "/migration/info/\(appId)"+"/"+"\(publicAddress)", method: .get, contentType: .json, body: nil, parameters:["cach_bust": String(Date().timeIntervalSince1970)])
        .then { request in
            return self.client.dataRequest(request)
        }
        .then { data in
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                if json?["wallet_blockchain_version"] as? String == "3" {
                     return Promise<Bool>().signal(true)
                } else {
                     return Promise<Bool>().signal( json?["should_migrate"] as? Int ?? 0 == 1 )
                }
            } else {
              return Promise<Bool>().signal(false)
            }
        }
    }
    @discardableResult
    func getBlockChainVersion(publicAddress:String) -> Promise<String?> {
        return client.buildRequest(path: "/users/\(publicAddress)/blockchain_version", method: .get, contentType: .json, body: nil, parameters:["cach_bust": String(Date().timeIntervalSince1970)])
        .then { request in
            return self.client.dataRequest(request)
        }
        .then { data in
            let result = String(data: data, encoding: .utf8)
            return Promise<String?>().signal(result)
        }
    }
}
