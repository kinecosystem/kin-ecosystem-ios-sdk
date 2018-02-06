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

public protocol EcosystemConfiguration {
    var baseURL: URL { get }
}

enum EcosystemNetError: Error {
    case network(Error)
    case responseError(ResponseError)
    case unknown
}

struct ResponseError: Codable, Error {
    var error: String
    var message: String?
    var code: Int32
}

class EcosystemNet {
    
    fileprivate var config: EcosystemConfiguration
    
    init(config: EcosystemConfiguration) {
        self.config = config
        
    }
    
    func offers() -> Promise<Data> {
        let p = Promise<Data>()
        let url = config.baseURL.appendingPathComponent("offers")
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                p.signal(EcosystemNetError.network(error))
                return
            }
            guard let data = data else {
                p.signal(EcosystemNetError.unknown)
                return
            }
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                    if let responseError = try? JSONDecoder().decode(ResponseError.self, from: data) {
                        p.signal(EcosystemNetError.responseError(responseError))
                    } else {
                        p.signal(EcosystemNetError.unknown)
                    }
                return
            }
            p.signal(data)
        }.resume()
        return p
    }
}
