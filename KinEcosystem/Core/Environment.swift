//
//  Environment.swift
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
    public init(blockchainURL: String,
                blockchainPassphrase: String,
                kinIssuer: String,
                marketplaceURL: String,
                webURL: String,
                BIURL: String) {
        self.blockchainURL = blockchainURL
        self.blockchainPassphrase = blockchainPassphrase
        self.kinIssuer = kinIssuer
        self.marketplaceURL = marketplaceURL
        self.webURL = webURL
        self.BIURL = BIURL
    }
}

public enum Environment {
    case playground
    case production
    case beta
    case custom(EnvironmentProperties)
    
    public var name: String {
        switch self {
        case .playground:
            return "playground"
        case .production:
            return "production"
        case .beta:
            return "beta"
        case .custom(_):
            return "custom"
        }
    }
    
    public var blockchainURL: String {
        switch self {
        case .playground:
            return "https://stellar.kinplayground.com"
        case .production:
            return "https://horizon-kin-ecosystem.kininfrastructure.com"
        case .beta:
            return "https://horizon-playground.kininfrastructure.com"
        case .custom(let envProps):
            return envProps.blockchainURL
        }
    }
    
    public var blockchainPassphrase: String {
        switch self {
        case .playground:
            return "ecosystem playground"
        case .production:
            return "Public Global Kin Ecosystem Network ; June 2018"
        case .beta:
            return "Kin Playground Network ; June 2018"
        case .custom(let envProps):
            return envProps.blockchainPassphrase
        }
    }
    
    public var kinIssuer: String {
        switch self {
        case .playground:
            return "GDVIWJ2NYBCPHMGTIBO5BBZCP5QCYC4YT4VINTV5PZOSE7BAJCH5JI64"
        case .production:
            return "GDF42M3IPERQCBLWFEZKQRK77JQ65SCKTU3CW36HZVCX7XX5A5QXZIVK"
        case .beta:
            return "GBC3SG6NGTSZ2OMH3FFGB7UVRQWILW367U4GSOOF4TFSZONV42UJXUH7"
        case .custom(let envProps):
            return envProps.kinIssuer
        }
    }
    
    public var marketplaceURL: String {
        switch self {
        case .playground:
            return "https://api.kinplayground.com/v1"
        case .production:
            return "https://api.kinmarketplace.com/v1"
        case .beta:
            return "https://api.kinecosystembeta.com/v1"
        case .custom(let envProps):
            return envProps.marketplaceURL
        }
    }
    
    public var webURL: String {
        switch self {
        case .playground:
            return "https://s3.amazonaws.com/assets.kinplayground.com/web-offers/cards-based/index.html"
        case .production:
            return "https://cdn.kinmarketplace.com"
        case .beta:
            return "https://s3.amazonaws.com/assets.kinplayground.com/web-offers/cards-based/index.html"
        case .custom(let envProps):
            return envProps.webURL
        }
    }
    
    public var BIURL: String {
        switch self {
        case .playground,
             .beta:
            return "https://kin-bi.appspot.com/eco_play_"
        case .production:
            return "https://kin-bi.appspot.com/eco_"
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
