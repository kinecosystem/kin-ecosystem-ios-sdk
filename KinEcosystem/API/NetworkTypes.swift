//
//  NetworkTypes.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 21/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation


class ResponseError: Codable, LocalizedError {
    var error: String
    var message: String?
    var code: Int32
    var httpResponse: HTTPURLResponse?
    var errorDescription: String? {
        return localizedDescription
    }
    var localizedDescription: String {
        return """
        error:      \(error)
        message:    \(message ?? "n/a")
        code:       \(code)
        """
    }
    
    enum ResponseKeys: String, CodingKey {
        case error
        case message
        case code
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: ResponseKeys.self)
        error = try values.decode(String.self, forKey: .error)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        code = try values.decode(Int32.self, forKey: .code)
    }
    
    init(code: Int32, error: String, message: String?) {
        self.code = code
        self.error = error
        self.message = message
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ResponseKeys.self)
        try container.encode(error, forKey: .error)
        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(message, forKey: .message)
    }
}

struct ClientErrorPatch: Encodable {
    var error: ResponseError
}

enum ContentType: String {
    case json = "application/json"
}

// using only these methods for now
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum SignInType: String {
    case jwt
    case whitelist
}

struct SignInData: Encodable {
    var jwt: String?
    var user_id: String?
    var app_id: String?
    var device_id: String
    var wallet_address: String
    var sign_in_type: String
    var api_key: String?
}

struct AuthToken: Codable {
    var token: String
    var activated: Bool
    var expiration_date: String
    var app_id: String
    var user_id: String
    var ecosystem_user_id: String
}

struct EarnResult: Encodable {
    var content: String
}

struct OpenOrderData: Decodable {
    var transaction_id: String?
    var sender_address: String?
    var recipient_address: String?
}

struct OpenOrder: Decodable {
    var id: String
    var expiration_date: String
    var blockchain_data: OpenOrderData?
    var offer_id: String
    var offer_type: String
    var title: String
    var description: String
    var amount: Int32
}

struct JWTOrderSubmission: Encodable {
    var jwt: String
}
