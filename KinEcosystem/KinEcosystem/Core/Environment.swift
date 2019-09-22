//
//  Environment.swift
//
//  Created by Elazar Yifrach on 18/06/2018.
//

import Foundation
import KinMigrationModule

public struct EnvironmentProperties: Codable, Equatable {
    let blockchainURL: URL
    let blockchainPassphrase: String
    let kinIssuer: String
    let marketplaceURL: String
    let webURL: String
    let BIURL: String
    public init(blockchainURL: URL,
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
    case test
    case custom(EnvironmentProperties)
    
    public var name: String {
        switch self {
        case .playground:
            return "playground"
        case .production:
            return "production"
        case .beta:
            return "beta"
        case .test:
            return "test"
        case .custom(_):
            return "custom"
        }
    }
    
    public var blockchainURL: URL {
        switch self {
        case .playground:
            return URL(string: "https://stellar.kinplayground.com")!
        case .production:
            return URL(string: "https://horizon-kin-ecosystem.kininfrastructure.com")!
        case .beta,
             .test:
            return URL(string: "https://horizon-playground.kininfrastructure.com")!
        case .custom(let envProps):
            return envProps.blockchainURL
        }
    }
    
    public var migrationURL: URL {
        switch self {
        case .playground,
             .test:
            return URL(string: "https://migration-service.kinecosystemtest.com")!
        case .beta:
            return URL(string: "https://migration-service.kinecosystembeta.com")!
        case .production:
            return URL(string: "https://migration-service.kinmarketplace.com")!
        case .custom:
            fatalError()
        }
    }
    
    public var blockchainPassphrase: String {
        switch self {
        case .playground:
            return "ecosystem playground"
        case .production:
            return "Public Global Kin Ecosystem Network ; June 2018"
        case .beta,
             .test:
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
        case .beta,
             .test:
            return "GBC3SG6NGTSZ2OMH3FFGB7UVRQWILW367U4GSOOF4TFSZONV42UJXUH7"
        case .custom(let envProps):
            return envProps.kinIssuer
        };
    }
    
    public var marketplaceURL: String {
        switch self {
        case .playground:
            return "https://api.kinplayground.com/v2"
        case .production:
            return "https://api.kinmarketplace.com/v2"
        case .beta:
            return "https://api.kinecosystembeta.com/v2"
        case .test:
            return "https://api.kinecosystemtest.com/v2"
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
            return "https://s3.amazonaws.com/assets.kinecosystembeta.com/web-offers/cards-based/index.html"
        case .test:
            return "https://s3.amazonaws.com/assets.kinecosystemtest.com/web-offers/cards-based/index.html"
        case .custom(let envProps):
            return envProps.webURL
        }
    }
    
    public var BIURL: String {
        switch self {
        case .playground,
             .beta,
             .test:
            return "https://bi.kinecosystembi.com/eco_play_"
        case .production:
            return "https://bi.kinecosystembi.com/eco_"
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

extension Environment {
    internal var mapToMigrationModuleNetwork: KinMigrationModule.Network {
        switch self {
        case .production:
            return .mainNet
        case .playground:
            return .playground
        case .beta,
             .test:
            return .testNet
        case .custom(let properties):
            return .custom(issuer: properties.kinIssuer, networkId: properties.blockchainPassphrase)
        }
    }
    
    internal func mapToMigrationModuleServiceProvider() throws -> KinMigrationModule.ServiceProviderProtocol {
        if case .custom = self {
            return try CustomServiceProvider(network: mapToMigrationModuleNetwork, migrateBaseURL: migrationURL, nodeURL: properties.blockchainURL)
        }
        else {
            return try ServiceProvider(network: mapToMigrationModuleNetwork, migrateBaseURL: migrationURL)
        }
    }
}
