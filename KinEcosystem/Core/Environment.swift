//
//  Environment.swift
//  Base64
//
//  Created by Elazar Yifrach on 18/06/2018.
//

import Foundation

public struct EnvironmentProperties: Codable, Equatable {
    let blockchainURL: String
    let blockchainPassphrase: String
    let kinIssuer: String
    let marketplaceURL: String
    let webURL: String
    let BIURL: String

    public static func ==(lhs: EnvironmentProperties, rhs: EnvironmentProperties) -> Bool {
        return lhs.blockchainURL == rhs.blockchainURL &&
            lhs.blockchainPassphrase == rhs.blockchainPassphrase &&
            lhs.kinIssuer == rhs.kinIssuer &&
            lhs.marketplaceURL == rhs.marketplaceURL &&
            lhs.webURL == rhs.webURL &&
            lhs.BIURL == rhs.BIURL
    }
}

public enum Environment {
    case playground
    case production
    case custom(EnvironmentProperties)
    
    public var blockchainURL: String {
        switch self {
        case .playground:
            return "https://stellar.kinplayground.com"
        case .production:
            return "https://horizon-kik.kininfrastructure.com"
        case .custom(let envProps):
            return envProps.blockchainURL
        }
    }
    
    public var blockchainPassphrase: String {
        switch self {
        case .playground:
            return "ecosystem playground"
        case .production:
            return "private testnet"
        case .custom(let envProps):
            return envProps.blockchainPassphrase
        }
    }
    
    public var kinIssuer: String {
        switch self {
        case .playground:
            return "GDVIWJ2NYBCPHMGTIBO5BBZCP5QCYC4YT4VINTV5PZOSE7BAJCH5JI64"
        case .production:
            return "GBQ3DQOA7NF52FVV7ES3CR3ZMHUEY4LTHDAQKDTO6S546JCLFPEQGCPK"
        case .custom(let envProps):
            return envProps.kinIssuer
        }
    }
    
    public var marketplaceURL: String {
        switch self {
        case .playground:
            return "http://api.kinplayground.com/v1"
        case .production:
            return "http://api.kinmarketplace.com/v1"
        case .custom(let envProps):
            return envProps.marketplaceURL
        }
    }
    
    public var webURL: String {
        switch self {
        case .playground:
            return "https://s3.amazonaws.com/assets.kinecosystembeta.com/index.html"
        case .production:
            return "http://htmlpoll.kinecosystem.com.s3-website-us-east-1.amazonaws.com"
        case .custom(let envProps):
            return envProps.webURL
        }
    }
    
    public var BIURL: String {
        switch self {
        case .playground:
            return ""
        case .production:
            return ""
        case .custom(let envProps):
            return envProps.BIURL
        }
    }
    
    public var properties: EnvironmentProperties {
        return EnvironmentProperties(blockchainURL: blockchainURL,
                                     blockchainPassphrase: blockchainPassphrase,
                                     kinIssuer: kinIssuer,
                                     marketplaceURL: marketplaceURL,
                                     webURL: webURL,
                                     BIURL: BIURL)
    }
}
