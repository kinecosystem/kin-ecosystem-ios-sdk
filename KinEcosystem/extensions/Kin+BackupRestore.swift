//
//  Kin+BackupRestore.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 15/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//
import KinCoreSDK
import KinUtil

@available(iOS 9.0, *)
extension Kin : KeystoreProvider {
    public func exportAccount(_ password: String) throws -> String {
        guard let core = core else {
            throw KinEcosystemError.client(.notStarted, nil)
        }
        guard isActivated else {
            throw KinEcosystemError.blockchain(.activation, nil)
        }
        return try core.blockchain.account.export(passphrase: password)
    }
    
    public func importAccount(keystore: String, password: String, completion: (Error?) -> ()) {
        guard let core = core else {
            completion(KinEcosystemError.client(.notStarted, nil))
            return
        }
        guard isActivated else {
            completion(KinEcosystemError.blockchain(.activation, nil))
            return
        }
        
        promise { (completion: (Bool?, Error?) -> ()) -> () in
            
            // someting with network that ends with either
            // completion(true, nil)
            // or completion(nil, someError)
            
            }.then { success -> Promise<Void> in
                
                promise { (completion: (Void?, Error?) -> ()) in
                    
                    // some other thing that either completes or fails
                    
                }
                
            }.then { _ in
                
            }.error { error in
                
        }
    }
        
        
    //try core.blockchain.importAccount(keystore, passphrase: password)
//    public func importAccount(_ jsonString: String,
//                              passphrase: String) throws -> Promise<Void> {
//        let p = Promise<Void>()
//        let account = try client.importAccount(jsonString, passphrase: passphrase)
//        self.account = account
//        return p
//        /*
//         - find wallet in accounts, or
//         - import
//         - set wallet address
//         - onboard
//         */
//    }
    
    public func validatePassword(_ password: String) -> Bool {
        // TODO: 
        return true
    }
}
