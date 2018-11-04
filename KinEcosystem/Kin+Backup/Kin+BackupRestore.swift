//
//  Kin+BackupRestore.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 15/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//
import KinCoreSDK

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
    
    public func importAccount(keystore: String, password: String) throws {
        guard let core = core else {
            throw KinEcosystemError.client(.notStarted, nil)
        }
        guard isActivated else {
            throw KinEcosystemError.blockchain(.activation, nil)
        }
        _ = try core.blockchain.client.importAccount(keystore, passphrase: password)
    }
    
    public func validatePassword(_ password: String) -> Bool {
        // TODO: 
        return true
    }
}
