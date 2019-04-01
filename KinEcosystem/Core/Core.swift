//
//  Core.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 04/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import KinMigrationModule

@available(iOS 9.0, *)
class Core {
    
    let network: EcosystemNet
    let data: EcosystemData
    let blockchain: Blockchain
    let environment: Environment
    var jwt: JWTObject? = nil
    private(set) var onboardInFlight = false
    private var isOnboarding: Bool {
        get {
            var result: Bool!
            synced(self) {
                result = onboardInFlight
            }
            return result
        }
        set {
            synced(self) {
                onboardInFlight = newValue
            }
        }
    }
    
    private var onboardPromise = Promise<Void>()
    private var onboardLock: Int = 1
    var onboarded: Bool {
        get {
            var result: Bool!
            synced(onboardLock) {
                result = jwt != nil && network.client.authToken != nil && blockchain.onboarded
            }
            return result
        }
    }
    
    init(environment: Environment, network: EcosystemNet, data: EcosystemData, blockchain: Blockchain) throws {
        self.network = network
        self.data = data
        self.blockchain = blockchain
        self.environment = environment
    }
    
    /*  get blockchain version for current app:
        applications/:app_id/blockchain_version
 
        get blockchain version and if account needs migration:
        migration/info/:app_id/:account_address
    */
    
    func onboard() -> Promise<Void> {
        
        if onboarded {
            return Promise<Void>().signal(())
        }
        
        if isOnboarding {
            return onboardPromise
        }
        
        onboardPromise = Promise<Void>()
        isOnboarding = true
        
        guard let encoded = jwt?.encoded else {
            self.isOnboarding = false
            onboardPromise.signal(KinEcosystemError.client(.jwtMissing, nil))
            return onboardPromise
        }
        
        network.authorize(jwt: encoded)
            
        .then { auth -> Promise<KinAccountProtocol> in
            try self.blockchain.start(with: auth)
            return self.blockchain.accountPromise
        }.then { account -> Promise<KinAccountProtocol> in
            self.updateWalletAddress(for: account)
        }.then { account in
            return self.blockchain.onboard()
                .then { _ in
                    Promise<KinAccountProtocol>().signal(account)
            }
        }.then {
            self.isOnboarding = false
            self.onboardPromise.signal(())
        }.error { error in
            self.isOnboarding = false
            self.onboardPromise.signal(error)
        }
        
        return onboardPromise
    }
    
    @discardableResult
    func offboard() -> Promise<Void> {
        let p = Promise<Void>()
        network.unAuthorize().then {
            self.blockchain.offboard()
            self.jwt = nil
            p.signal(())
        }
        return p
    }
    
    func importAccount(keystore: String, password: String, completion: @escaping (Error?) -> ()) {
        
        guard network.client.authToken != nil else {
            completion(KinEcosystemError.service(.notLoggedIn, nil))
            return
        }
        var account: KinAccountProtocol!
        
        do {
            account = try blockchain.accountForImporting(keystore: keystore, password: password)
        } catch {
            completion(error)
            return
        }
        
        updateWalletAddress(for: account)
        .then { _ in
            
            var data = account.kinExtraData
            data.backedUp = true
            data.onboarded = true
            account.kinExtraData = data
            
            completion(nil)
            
            _ = self.network.dataAtPath("offers")
            .then { offersData in
                self.data.sync(OffersList.self, with: offersData)
            }.then {
                self.network.dataAtPath("orders")
            }.then { ordersData in
                self.data.sync(OrdersList.self, with: ordersData)
            }
        }.error { error in
           completion(error)
        }
        
    }
    
    fileprivate func updateWalletAddress(for account: KinAccountProtocol) -> Promise<KinAccountProtocol> {
        let p = Promise<KinAccountProtocol>()
        do {
            let data = try JSONEncoder().encode(UserProperties(wallet_address: account.publicAddress))
            network.client.buildRequest(path: "users/me", method: .patch, body: data)
                .then { request in
                    self.network.client.request(request)
                }.then { _ in
                    try self.blockchain.setActiveAccount(account)
                    p.signal(account)
                }.error { error in
                    p.signal(error)
            }
        } catch {
            p.signal(error)
            return p
        }
        
        return p
    }
}
