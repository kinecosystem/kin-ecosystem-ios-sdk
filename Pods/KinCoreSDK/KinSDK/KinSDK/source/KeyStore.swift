//
//  KeyStore.swift
//  KinCoreSDK
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit

enum KeyStoreErrors: Error {
    case storeFailed
    case loadFailed
    case noSalt
    case noPepper
    case noSeed
    case noSecretKey
    case keypairGenerationFailed
    case encryptionFailed
}

protocol AccountStorage {
    static func nextStorageKey() -> String
    static func save(_ accountData: Data, forKey key: String) -> Bool
    static func retrieve(_ key: String) -> Data?
    static func account(at index: Int) -> StellarAccount?
    static func remove(at index: Int) -> Bool
    static func count() -> Int
    static func clear()
}

private let StorageClass: AccountStorage.Type = KeychainStorage.self

public struct AccountData: Codable {
    let pkey: String
    let seed: String
    let salt: String
    let extra: Data?
}

public class StellarAccount: Account {
    fileprivate let storageKey: String

    public var publicKey: String? {
        guard let accountData = try? accountData() else {
            return nil
        }

        return accountData.pkey
    }

    public func extra() throws -> Data? {
        return try accountData().extra
    }

    public var sign: (([UInt8]) throws -> [UInt8])?

    public func sign(message: [UInt8], passphrase: String) throws -> [UInt8] {
        guard let signingKey = secretKey(passphrase: passphrase) else {
            throw KeyStoreErrors.noSecretKey
        }

        return try KeyUtils.sign(message: message, signingKey: signingKey)
    }

    fileprivate func secretKey(passphrase: String) -> [UInt8]? {
        guard let seed = seed(passphrase: passphrase) else {
            return nil
        }

        guard let keypair = KeyUtils.keyPair(from: seed) else {
            return nil
        }

        return keypair.secretKey
    }

    init(storageKey: String) {
        self.storageKey = storageKey
    }

    fileprivate func accountData() throws -> AccountData {
        guard let data = StorageClass.retrieve(storageKey) else {
            throw KeyStoreErrors.loadFailed
        }

        return try JSONDecoder().decode(AccountData.self, from: data)
    }

    private func seed(passphrase: String) -> [UInt8]? {
        guard let accountData = try? accountData() else {
            return nil
        }

        return StellarAccount.seed(accountData: accountData, passphrase: passphrase)
    }

    fileprivate static func seed(accountData: AccountData, passphrase: String) -> [UInt8]? {
        guard let seed = try? KeyUtils.seed(from: passphrase,
                                            encryptedSeed: accountData.seed,
                                            salt: accountData.salt) else {
                                                return nil
        }

        return seed
    }
}

public struct KeyStore {
    public static func newAccount(passphrase: String) throws -> StellarAccount {
        let storageKey = StorageClass.nextStorageKey()

        try save(accountData: try accountData(passphrase: passphrase), key: storageKey)

        let account = StellarAccount(storageKey: storageKey)

        return account
    }

    public static func account(at index: Int) -> StellarAccount? {
        return StorageClass.account(at: index)
    }

    public static func set(extra: Data?, for account: StellarAccount) throws {
        let accountData = try account.accountData()

        let newData = AccountData(pkey: accountData.pkey,
                                  seed: accountData.seed,
                                  salt: accountData.salt,
                                  extra: extra)

        try save(accountData: newData, key: account.storageKey)
    }

    @discardableResult
    public static func remove(at index: Int) -> Bool {
        return StorageClass.remove(at: index)
    }

    public static func count() -> Int {
        return StorageClass.count()
    }

    @discardableResult
    public static func importSecretSeed(_ seed: String, passphrase: String) throws -> StellarAccount {
        let seedData = StellarKit.KeyUtils.key(base32: seed)

        let storageKey = StorageClass.nextStorageKey()

        try save(accountData: try accountData(passphrase: passphrase, seed: seedData), key: storageKey)

        let account = StellarAccount(storageKey: storageKey)

        return account
    }

    public static func importAccount(_ accountData: AccountData,
                                     passphrase: String,
                                     newPassphrase: String) throws {
        // Re-encrypting will test that the passphrase is correct.
        let accountData = try reencrypt(accountData,
                                        passphrase: passphrase,
                                        newPassphrase: newPassphrase)

        try save(accountData: accountData, key: StorageClass.nextStorageKey())
    }

    public static func exportAccount(account: StellarAccount,
                                     passphrase: String,
                                     newPassphrase: String) -> AccountData? {
        if let accountData = try? account.accountData() {
            let reencryptedAD: AccountData?
            if passphrase != newPassphrase {
                reencryptedAD = try? reencrypt(accountData,
                                               passphrase: passphrase,
                                               newPassphrase: newPassphrase)
            } else {
                reencryptedAD = accountData
            }

            if let ad = reencryptedAD {
                return ad
            }
        }

        return nil
    }

    private static func accountData(passphrase: String,
                                    seed: [UInt8]? = nil) throws -> AccountData {
        guard let salt = KeyUtils.salt() else {
            throw KeyStoreErrors.noSalt
        }

        guard let seed = seed ?? KeyUtils.seed() else {
            throw KeyStoreErrors.noSeed
        }

        let skey = try KeyUtils.keyHash(passphrase: passphrase, salt: salt)

        guard let encryptedSeed = KeyUtils.encryptSeed(seed, secretKey: skey) else {
            throw KeyStoreErrors.encryptionFailed
        }

        guard let keypair = KeyUtils.keyPair(from: seed) else {
            throw KeyStoreErrors.keypairGenerationFailed
        }

        return AccountData(pkey: StellarKit.KeyUtils.base32(publicKey: keypair.publicKey),
                           seed: encryptedSeed.hexString,
                           salt: salt,
                           extra: nil)
    }

    private static func reencrypt(_ accountData: AccountData,
                                  passphrase: String,
                                  newPassphrase: String) throws -> AccountData {
        let eseed = accountData.seed
        let salt = accountData.salt

        guard let newSalt = KeyUtils.salt() else {
            throw KeyStoreErrors.noSalt
        }

        let skey = try KeyUtils.keyHash(passphrase: newPassphrase, salt: newSalt)
        let seed = try KeyUtils.seed(from: passphrase, encryptedSeed: eseed, salt: salt)

        guard let encryptedSeed = KeyUtils.encryptSeed(seed, secretKey: skey) else {
            throw KeyStoreErrors.encryptionFailed
        }

        return AccountData(pkey: accountData.pkey,
                           seed: encryptedSeed.hexString,
                           salt: newSalt,
                           extra: nil)
    }

    private static func save(accountData: AccountData, key: String) throws {
        let data = try JSONEncoder().encode(accountData)

        guard StorageClass.save(data, forKey: key) else {
            throw KeyStoreErrors.storeFailed
        }
    }
}

extension KeyStore {
    /**
     **WARNING!  WARNING!  WARNING!  WARNING!  WARNING!  WARNING!**
     This is for internal use, only.  It will delete _ALL_ keychain entries for the app, not just
     those used by this SDK.

     *It is intended for use by unit tests.*
     */
    static func removeAll() {
        StorageClass.clear()
    }
}

private struct KeychainStorage: AccountStorage {
    private static let keychainPrefix = "__swifty_stellar_"
    private static let keychain = KeychainSwift(keyPrefix: keychainPrefix)

    static func nextStorageKey() -> String {
        let keys = self.keys()

        if keys.count == 0 {
            return String(format: "%06d", 0)
        }
        else if let key = keys.last,
            let indexStr = key.split(separator: "_").last,
            let last = Int(indexStr)
        {
            let index = last + 1
            return String(format: "%06d", index)
        }
        else {
            return ""
        }
    }

    static func save(_ accountData: Data, forKey key: String) -> Bool {
        return keychain.set(accountData, forKey: key, withAccess: .accessibleAfterFirstUnlock)
    }

    static func retrieve(_ key: String) -> Data? {
        return keychain.getData(key)
    }

    static func delete(_ key: String) -> Bool {
        return keychain.delete(key)
    }

    static func account(at index: Int) -> StellarAccount? {
        let keys = self.keys()
        
        guard index < keys.count else {
            return nil
        }
        
        guard let indexStr = keys[index].split(separator: "_").last else {
            return nil
        }
        
        return StellarAccount(storageKey: String(indexStr))
    }
    
    @discardableResult
    static func remove(at index: Int) -> Bool {
        let key = keys()[index]
        
        guard
            index < keys().count,
            let indexStr = key.split(separator: "_").last else {
                return false
        }
        
        return delete(String(indexStr))
    }

    static func count() -> Int {
        return keys().count
    }

    static func keys() -> [String] {
        return (keychain.getAllKeys() ?? [])
            .filter { $0.starts(with: keychainPrefix) }
            .sorted()
    }

    fileprivate static func clear() {
        keychain.clear()
    }

    static func removePrefix(_ key: String) -> String? {
        if let string = key.split(separator: "_").last {
            return String(string)
        }
        return nil
    }
}

// MARK: Migration

extension KeyStore {
    internal static func migrateIfNeeded() {
        let key = "__KinCoreDidMigrateKeychainAccess"

        guard !UserDefaults.standard.bool(forKey: key) else {
            return
        }

        KeychainStorage.migrate()
        UserDefaults.standard.set(true, forKey: key)
    }
}

extension KeychainStorage {
    /**
     Migrate the keychain entries access type.

     Previous versions of the keychain storage were saving data with the default access type.
     In order to update the access type, the existing keys need to simply be resaved.
     */
    fileprivate static func migrate() {
        let keys = self.keys().compactMap { removePrefix($0) }

        for key in keys {
            if let data = retrieve(key) {
                _ = delete(key)
                _ = save(data, forKey: key)
            }
        }
    }
}
