//
//  Core.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 04/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

class Core {
    
    let network: EcosystemNet
    let data: EcosystemData
    let blockchain: Blockchain
    
    init(network: EcosystemNet, data: EcosystemData, blockchain: Blockchain) {
        self.network = network
        self.data = data
        self.blockchain = blockchain
    }
}
