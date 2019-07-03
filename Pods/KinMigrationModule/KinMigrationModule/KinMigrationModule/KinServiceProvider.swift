//
//  KinServiceProvider.swift
//  KinMigrationModule
//
//  Created by Corey Werner on 06/01/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

public protocol ServiceProviderProtocol {
    var network: Network { get }
    var migrateBaseURL: URL? { get }
}

extension ServiceProviderProtocol {
    func migrateURL(publicAddress: String) throws -> URL {
        guard let migrateBaseURL = migrateBaseURL else {
            throw KinMigrationError.invalidMigrationURL
        }

        var urlComponents = URLComponents(url: migrateBaseURL, resolvingAgainstBaseURL: false)
        urlComponents?.path = "/migrate"
        urlComponents?.queryItems = [URLQueryItem(name: "address", value: publicAddress)]

        if let url = urlComponents?.url {
            return url
        }
        else {
            throw KinMigrationError.invalidMigrationURL
        }
    }
}

public struct ServiceProvider: ServiceProviderProtocol {
    private(set) public var network: Network
    private(set) public var migrateBaseURL: URL?

    /**
     Initializes and returns a service provider object having the given network.

     This class can not be used with a type `.custom` network.

     - Parameter network: The `Network` which the client connects to.
     - Parameter migrateBaseURL: The base `URL` of the migration service.

     - Throws: An error if the `network` is `.custom`.
     */
    public init(network: Network, migrateBaseURL: URL? = nil) throws {
        if case .custom = network {
            throw KinMigrationError.invalidNetwork
        }

        self.network = network
        self.migrateBaseURL = migrateBaseURL
    }
}

public struct CustomServiceProvider: ServiceProviderProtocol {
    private(set) public var network: Network
    private(set) public var migrateBaseURL: URL?
    public let nodeURL: URL

    /**
     Initializes and returns a service provider object having the given network and node URL.

     This class can only be used with a type `.custom` network.

     - Parameter network: The `Network` which the client connects to.
     - Parameter migrateBaseURL: The base `URL` of the migration service.
     - Parameter nodeURL: The `URL` of the node.

     - Throws: An error if the `network` is not `.custom`.
     */
    public init(network: Network, migrateBaseURL: URL? = nil, nodeURL: URL) throws {
        guard case .custom = network else {
            throw KinMigrationError.invalidNetwork
        }

        self.network = network
        self.migrateBaseURL = migrateBaseURL
        self.nodeURL = nodeURL
    }
}
