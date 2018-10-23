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
public class RecoveryManager: NSObject {
    private let storeProvider: KeystoreProvider
    private var presentor: UIViewController!
    private var isIdle = true
    
    public init(with storeProvider: KeystoreProvider) {
        // ???: why not pass the provider into the start method to reduce the unnecessary reference
        self.storeProvider = storeProvider
    }
    
    public func start(_ phase: RecoveryPhase,
                      from viewController: UIViewController,
                      events: KinRecoveryEventsHandler,
                      completion: KinRecoveryCompletionHandler) {
        presentor = viewController
        
        let navigationController: NavigationController
        
        switch phase {
        case .backup:
            navigationController = BackupNavigationController(keystoreProvider: storeProvider)
        case .restore:
            navigationController = RestoreNavigationController(keystoreProvider: storeProvider)
        }
        
        navigationController.dismissBarButtonItem.target = self
        navigationController.dismissBarButtonItem.action = #selector(dismissFlow)
        presentor.present(navigationController, animated: true)
    }
    
    @objc private func dismissFlow() {
        presentor.dismiss(animated: true)
    }
}
