//
//  Recovery.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 15/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import KinUtil

public protocol KeystoreProvider {
    func exportAccount(_ password: String) throws
    func importAccount(keystore: String, password: String) throws
    func validatePassword(_ password: String) throws
}

public typealias KinRecoveryCompletionHandler = (_ success: Bool) -> ()
public typealias KinRecoveryEventsHandler = (_ event: RecoveryEvent) -> ()

public enum RecoveryPhase {
    case backup
    case restore
}

public enum RecoveryEvent {
    case backup(RecoveryEventType)
    case restore(RecoveryEventType)
}
public enum RecoveryEventType {
    case nextTapped
    case passwordMismatch
    case qrMailSent
}

@available(iOS 9.0, *)
public class RecoveryManager {
    
    private let storeProvider: KeystoreProvider
    private var presentor: UIViewController!
    private var isIdle = true
    
    public init(with storeProvider: KeystoreProvider) {
        self.storeProvider = storeProvider
    }
    
    public func start(_ phase: RecoveryPhase,
                      from viewController: UIViewController,
                      events: KinRecoveryEventsHandler,
                      completion: KinRecoveryCompletionHandler) {
        presentor = viewController
        switch phase {
        case .backup:
            backupFlow(events: events, completion: completion)
        default:
            restoreFlow(events: events, completion: completion)
        }
    }
    
    private func backupFlow(events: KinRecoveryEventsHandler,
                    completion: KinRecoveryCompletionHandler) {
        /*
         screens:
            - welcome
            - set password
            - send qr
            - confirmation
         
         tasks:
            - create nibs
            - make promises for flows (ui and other)
            - actually impl backup/res
            - impl kin protocol
         
         */
        
        
    }
    
    private func restoreFlow(events: KinRecoveryEventsHandler,
                     completion: KinRecoveryCompletionHandler) {
        
    }
}

          
