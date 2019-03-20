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
        guard isActivated, var account = core.blockchain.account else {
            throw KinEcosystemError.service(.notLoggedIn, nil)
        }
        let result = try account.export(passphrase: password)
        var data = account.kinExtraData
        data.backedUp = true
        account.kinExtraData = data
        return result
    }
    
    public func importAccount(keystore: String, password: String, completion: @escaping (Error?) -> ()) {
        
        guard let core = core else {
            completion(KinEcosystemError.client(.notStarted, nil))
            return
        }
        
        core.importAccount(keystore: keystore, password: password, completion: completion)
        
    }
    
    public func validatePassword(_ password: String) -> Bool {
        let range = NSRange(location: 0, length: password.utf16.count)
        return passRegex.firstMatch(in: password, options: [], range: range) != nil
    }
    
}
