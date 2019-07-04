//
//  KinClientFactory.swift
//  multi
//
//  Created by Corey Werner on 10/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

class KinClientFactory {
    let version: KinVersion

    init(version: KinVersion) {
        self.version = version
    }

    private func nodeURL(_ serviceProvider: ServiceProviderProtocol) -> URL {
        if let serviceProvider = serviceProvider as? CustomServiceProvider {
            return serviceProvider.nodeURL
        }
        else {
            switch serviceProvider.network {
            case .mainNet:
                switch version {
                case .kinCore:
                    return URL(string: "https://horizon-ecosystem.kininfrastructure.com")!
                case .kinSDK:
                    return URL(string: "https://horizon.kinfederation.com")!
                }
            default:
                switch version {
                case .kinCore:
                    return URL(string: "https://horizon-playground.kininfrastructure.com")!
                case .kinSDK:
                    return URL(string: "https://horizon-testnet.kininfrastructure.com")!
                }
            }
        }
    }

    func KinClient(serviceProvider: ServiceProviderProtocol, appId: AppId) -> KinClientProtocol {
        let url = nodeURL(serviceProvider)

        switch version {
        case .kinCore:
            return WrappedKinCoreClient(with: url, network: serviceProvider.network, appId: appId)
        case .kinSDK:
            return WrappedKinSDKClient(with: url, network: serviceProvider.network, appId: appId)
        }
    }
}
