//
//  KinAccounts.swift
//  KinSDK
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import Foundation

/**
 `KinAccounts` wraps the `KinAccount` list.
 */
public final class KinAccounts {
    private var cache = [Int: KinAccount]()
    private let cacheLock = NSLock()
    
    private let node: Stellar.Node
    private let appId: AppId

    /**
     Number of `KinAccount` objects.
     */
    public var count: Int {
        return KeyStore.count()
    }

    /**
     Retrieve a `KinAccount` at a given index.

     - Parameter index: The index of the list of accounts to return.

     - Returns: The `KinAccount` at index if it exists, nil otherwise.
     */
    public subscript(_ index: Int) -> KinAccount? {
        self.cacheLock.lock()
        defer {
            self.cacheLock.unlock()
        }
        
        return account(at: index)
    }
    
    func createAccount() throws -> KinAccount {
        self.cacheLock.lock()
        defer {
            self.cacheLock.unlock()
        }
        
        let account = createKinAccount(stellarAccount: try KeyStore.newAccount(passphrase: ""))

        cache[count - 1] = account

        return account
    }
    
    func deleteAccount(at index: Int) throws {
        self.cacheLock.lock()
        defer {
            self.cacheLock.unlock()
        }
        
        guard let account = account(at: index) as? KinStellarAccount else {
            throw KinError.internalInconsistency
        }
        
        guard KeyStore.remove(at: index) else {
            throw KinError.unknown
        }
        
        account.deleted = true
        
        shiftCache(for: index)
    }
    
    private func shiftCache(for index: Int) {
        let indexesToShuffle = Array(cache.keys).filter({ $0 > index }).sorted()
        
        cache[index] = nil
        
        var tempCache = [Int: KinAccount]()
        for i in indexesToShuffle {
            tempCache[i - 1] = cache[i]
            
            cache[i] = nil
        }
        
        for (index, account) in tempCache {
            cache[index] = account
        }
    }
    
    private func account(at index: Int) -> KinAccount? {
        return cache[index] ?? {
            if index < self.count, let stellarAccount = KeyStore.account(at: index) {
                let kinAccount = createKinAccount(stellarAccount: stellarAccount)
                
                cache[index] = kinAccount
                
                return kinAccount
            }
            
            return nil
        }()
    }
    
    init(node: Stellar.Node, appId: AppId) {
        self.node = node
        self.appId = appId
    }
    
    private func createKinAccount(stellarAccount: StellarAccount) -> KinStellarAccount {
        return KinStellarAccount(stellarAccount: stellarAccount, node: node, appId: appId)
    }
    
    func flushCache() {
        for account in cache.values {
            (account as? KinStellarAccount)?.deleted = true
        }
        
        cache.removeAll()
    }
}

extension KinAccounts: Sequence {
    /**
     Provides an `AnyIterator` for the list of `KinAccount`'s.

     - Returns: An iterator for the list of `KinAccount`'s.
     */
    public func makeIterator() -> AnyIterator<KinAccount?> {
        return AnyIterator(stride(from: 0, to: self.count, by: 1).lazy.map { self[$0] }.makeIterator())
    }
}

extension KinAccounts: RandomAccessCollection {
    /**
     The start index of the list of `KinAccount`.
     */
    public var startIndex: Int {
        return 0
    }

    /**
     The upper end index of the list of `KinAccount`.
     */
    public var endIndex: Int {
        return KeyStore.count()
    }
}

extension KinAccounts {
    /**
     The first `KinAccount` object if it exists.
     */
    public var first: KinAccount? {
        return count > 0 ? self[0] : nil
    }

    /**
     The last `KinAccount` object if it exists.
     */
    public var last: KinAccount? {
        return count > 0 ? self[self.count - 1] : nil
    }
}
