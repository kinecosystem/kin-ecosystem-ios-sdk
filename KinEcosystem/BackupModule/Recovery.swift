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
    private let navigationController = NavigationController()
    
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
        
        
        let dismissItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissFlow))
        dismissItem.tintColor = .white
        
        let introViewController = BackupIntroViewController(nibName: "BackupExplanationViewController", bundle: Bundle.ecosystem)
        introViewController.navigationItem.leftBarButtonItem = dismissItem
        introViewController.continueButton.addTarget(self, action: #selector(pushPasswordViewController), for: .touchUpInside)
//        introViewController.continueButton.addTarget(self, action: #selector(pushQRViewController), for: .touchUpInside)
        
        navigationController.viewControllers = [introViewController]
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.tintColor = .black
        presentor.present(navigationController, animated: true)
    }
    
    private func restoreFlow(events: KinRecoveryEventsHandler,
                     completion: KinRecoveryCompletionHandler) {
        
    }
    
    // MARK: Navigation
    
    @objc private func dismissFlow() {
        presentor.dismiss(animated: true)
    }
    
    @objc private func pushPasswordViewController() {
        let passwordViewController = PasswordEntryViewController(nibName: "PasswordEntryViewController",
                                                                 bundle: Bundle.ecosystem)
        passwordViewController.delegate = self
        navigationController.pushViewController(passwordViewController, animated: true)
    }
    
    @objc private func pushQRViewController() {
        let qrViewController = QRViewController(qrString: "exported keyphrase etc") // TODO:
        qrViewController.continueButton.addTarget(self, action: #selector(pushCompletedViewController), for: .touchUpInside)
        navigationController.pushViewController(qrViewController, animated: true)
    }
    
    @objc private func pushCompletedViewController() {
        let completedViewController = BackupCompletedViewController(nibName: "BackupExplanationViewController", bundle: Bundle.ecosystem)
        navigationController.pushViewController(completedViewController, animated: true)
    }
}

@available(iOS 9.0, *)
extension RecoveryManager: PasswordEntryDelegate {
    func validatePasswordConformance(_ password: String) -> Bool {
        do {
            try storeProvider.validatePassword(password)
            return true
        }
        catch {
            return false
        }
    }
}
