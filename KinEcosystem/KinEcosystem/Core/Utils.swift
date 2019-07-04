//
//  Utils.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 08/01/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import Foundation

func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    defer {
        objc_sync_exit(lock)
    }
    closure()
}

public extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    public class func once(token: String, block:() -> ()) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}

