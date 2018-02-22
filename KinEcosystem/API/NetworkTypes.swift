//
//  NetworkTypes.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 21/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation


struct ResponseError: Decodable, Error {
    var error: String
    var message: String?
    var code: Int32
}

enum ContentType: String {
    case json = "application/json"
}

// using only these methods for now
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
}

enum SignInType: String {
    case jwt
    case whitelist
}

struct SignInData: Encodable {
    var jwt: String?
    var user_id: String
    var app_id: String
    var device_id: String
    var public_address: String
    var sign_in_type: String
}

struct AuthToken: Codable {
    var token: String
    var activated: Bool
    var expiration_date: String
}
