//
//  KinAccounts.swift
//  KinCoreSDK
//
//  Created by Kin Foundation
//  Copyright © 2017 Kin Foundation. All rights reserved.
//

import Foundation
import StellarKit

public final class KinAccounts {
    private var cache = [Int: KinAccount]()
    private let cacheLock = NSLock()
    
    private let node: Stellar.Node
    private let asset: Asset

    public var count: Int {
        return KeyStore.count()
    }
    
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
        
        let account = try KinStellarAccount(stellarAccount: KeyStore.newAccount(passphrase: ""),
                                            asset: asset,
                                            node: node)

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
        return cache[index] ??
            {
                if index < self.count,
                    let stellarAccount = KeyStore.account(at: index) {
                    let kinAccount = KinStellarAccount(stellarAccount: stellarAccount,
                                                       asset: asset,
                                                       node: node)
                    
                    cache[index] = kinAccount
                    
                    return kinAccount
                }
                
                return nil
            }()
    }
    
    init(node: Stellar.Node, asset: Asset) {
        self.node = node
        self.asset = asset
    }
    
    func flushCache() {
        for account in cache.values {
            (account as? KinStellarAccount)?.deleted = true
        }
        
        cache.removeAll()
    }
}

extension KinAccounts: Sequence {
    public func makeIterator() -> AnyIterator<KinAccount?> {
        var index = 0

        return AnyIterator {
            let account = index <= self.count ? self[index] : nil

            index += 1
            
            return account
        }
    }
}

extension KinAccounts: RandomAccessCollection {
    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return KeyStore.count()
    }
}

extension KinAccounts {
    public var first: KinAccount? {
        return count > 0 ? self[0] : nil
    }

    public var last: KinAccount? {
        return count > 0 ? self[self.count - 1] : nil
    }
}
