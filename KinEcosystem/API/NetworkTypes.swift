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
    var sign_in_type: String
}

struct AuthToken: Codable {
    var token: String
    var activated: Bool
    var expiration_date: String
    var app_id: String
    var user_id: String
    var ecosystem_user_id: String
}

struct RegisterResponse: Decodable {
    var auth: AuthToken
    var user: UserProfile
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

public struct UserStats: Decodable, CustomStringConvertible {
    public var description: String {
        return """
        earn count:     \(earnCount)
        spend count:    \(spendCount)
        last earn date: \({ () -> String in
        guard let dateRawString = lastEarnDate,
              let dateDescription = Iso8601DateFormatter.string(from: dateRawString) else {
            return "n/a"
        }
        return dateDescription
        }()
        )
        last spend date: \({ () -> String in
        guard let dateRawString = lastSpendDate,
        let dateDescription = Iso8601DateFormatter.string(from: dateRawString) else {
        return "n/a"
        }
        return dateDescription
        }()
        )
        """
    }
    var earnCount: Int32
    var spendCount: Int32
    var lastEarnDate: Date?
    var lastSpendDate: Date?
    enum UserStatsKeys: String, CodingKey {
        case earnCount = "earn_count"
        case spendCount = "spend_count"
        case lastEarnDate = "last_earn_date"
        case lastSpendDate = "last_spend_date"
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: UserStatsKeys.self)
        earnCount = try values.decode(Int32.self, forKey: .earnCount)
        spendCount = try values.decode(Int32.self, forKey: .spendCount)
        if let earnDateString = try values.decodeIfPresent(String.self, forKey: .lastEarnDate) {
            lastEarnDate = Iso8601DateFormatter.date(from: earnDateString)
        }
        if let lastSpendString = try values.decodeIfPresent(String.self, forKey: .lastSpendDate) {
            lastSpendDate = Iso8601DateFormatter.date(from: lastSpendString)
        }
    }
}

public struct UserProfile: Decodable {
    var createdDate: Date?
    var stats: UserStats?
    enum UserProfileKeys: String, CodingKey {
        case createdDate = "created_date"
        case stats
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: UserProfileKeys.self)
        if let createdDateString = try values.decodeIfPresent(String.self, forKey: .createdDate) {
            createdDate = Iso8601DateFormatter.date(from: createdDateString)
        }
        stats = try values.decodeIfPresent(UserStats.self, forKey: .stats)
    }
}

public struct UserProperties: Encodable {
    var wallet_address: String
}

public struct JWTObject {
    let appId: String
    let deviceId: String
    let userId: String
    let encoded: String
    init(with string: String) throws {
        guard   let jwtJson = try? string.jwtJson(),
            let body = jwtJson["body"] as? [String: Any],
            let user = body["user_id"] as? String,
            let device = body["device_id"] as? String,
            let id = body["iss"] as? String else {
                throw KinEcosystemError.client(.badRequest, nil)
        }
        encoded = string
        appId = id
        deviceId = device
        userId = user
    }
}
