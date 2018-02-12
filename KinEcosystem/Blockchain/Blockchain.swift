//
//  Blockchain.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 11/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import KinSDK

class Blockchain {
    let client: KinClient
    init() throws {
        // TODO: inject test/main
        client = try KinClient(with: URL(string: "https://horizon-testnet.stellar.org")!, networkId: .custom(issuer: "GBOJSMAO3YZ3CQYUJOUWWFV37IFLQVNVKHVRQDEJ4M3O364H5FEGGMBH",
            stellarNetworkId: NetworkId.testNet.stellarNetworkId))
        if client.accounts[0] == nil {
            _ = try client.addAccount(with: "")
        }
    }
}

