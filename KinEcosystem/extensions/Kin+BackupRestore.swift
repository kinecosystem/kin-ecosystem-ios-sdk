//
//  Kin+BackupRestore.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 15/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//
import KinCoreSDK
import KinUtil

let passRegex = try! NSRegularExpression(pattern: "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{9,}$", options: [])

@available(iOS 9.0, *)
extension Kin : KeystoreProvider {
    public func exportAccount(_ password: String) throws -> String {
        guard let core = core else {
            throw KinEcosystemError.client(.notStarted, nil)
        }
        guard isActivated else {
            throw KinEcosystemError.blockchain(.activation, nil)
        }
        let result = try core.blockchain.account.export(passphrase: password)
        var data = core.blockchain.account.kinExtraData
        data.backedUp = true
        core.blockchain.account.kinExtraData = data
        return result
    }
    
    public func importAccount(keystore: String, password: String, completion: @escaping (Error?) -> ()) {
        
        guard let core = core else {
            completion(KinEcosystemError.client(.notStarted, nil))
            return
        }
        guard isActivated else {
            completion(KinEcosystemError.blockchain(.activation, nil))
            return
        }
        
        promise { (handler: (KinAccount?, Error?) -> ()) -> () in
            
            do {
                let account = try core.blockchain.accountForImporting(keystore: keystore, password: password)
                handler(account, nil)
            } catch {
                handler(nil, error)
            }
            
        }.then { account -> Promise<Void> in
                
            promise { (handler: @escaping (Void?, Error?) -> ()) in
                do {
                    let data = try JSONEncoder().encode(UserProperties(wallet_address: account.publicAddress))
                    core.network.client.buildRequest(path: "users", method: .patch, body: data)
                    .then { request in
                        core.network.client.request(request)
                    }.then { _ in
                        core.blockchain.setActiveAccount(account)
                        handler((), nil)
                    }.error { error in
                        handler(nil, error)
                    }
                } catch {
                    handler(nil, error)
                }
            }
            
        }.then {
            completion(nil)
        }.error { error in
            completion(error)
        }
        
    }
    
    public func validatePassword(_ password: String) -> Bool {
        let range = NSRange(location: 0, length: password.utf16.count)
        return passRegex.firstMatch(in: password, options: [], range: range) != nil
    }
    
}
