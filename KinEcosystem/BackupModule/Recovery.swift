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

private enum RecoveryPresentationType {
    case pushed
    case presented
}

private struct RecoveryInstance {
    let presentationType: RecoveryPresentationType
    let flowController: FlowController
    let completion: KinRecoveryCompletionHandler
}

@available(iOS 9.0, *)
public class RecoveryManager: NSObject {
    private let storeProvider: KeystoreProvider
    private var presentor: UIViewController?
    private var recoveryInstance: RecoveryInstance?
    
    public init(with storeProvider: KeystoreProvider) {
        self.storeProvider = storeProvider
    }
    
    /**
     Start a backup or recovery phase by pushing the view controllers onto a navigation controller.
     
     If the navigation controller has a `topViewController`, then the stack will be popped to that
     view controller upon completion. Otherwise it's up to the user to perform the final navigation.
     
     - Parameter phase: Perform a backup or restore
     - Parameter navigationController: The navigation controller being pushed onto
     - Parameter events:
     - Parameter completion:
     */
    public func start(_ phase: RecoveryPhase,
                      pushedOnto navigationController: UINavigationController,
                      events: KinRecoveryEventsHandler,
                      completion: @escaping KinRecoveryCompletionHandler)
    {
        guard recoveryInstance == nil else {
            completion(false)
            return
        }
        
        let flowController = createFlowController(phase: phase, keystoreProvider: storeProvider, navigationController: navigationController)
        let isStackEmpty = navigationController.viewControllers.isEmpty
        navigationController.pushViewController(flowController.entryViewController, animated: !isStackEmpty)
        
        recoveryInstance = RecoveryInstance(presentationType: .pushed, flowController: flowController, completion: completion)
    }
    
    /**
     Start a backup or recovery phase by presenting the navigation controller onto a view controller.
     
     - Parameter phase: Perform a backup or restore
     - Parameter viewController: The view controller being presented onto
     - Parameter events:
     - Parameter completion:
     */
    public func start(_ phase: RecoveryPhase,
                      presentedOn viewController: UIViewController,
                      events: KinRecoveryEventsHandler,
                      completion: @escaping KinRecoveryCompletionHandler)
    {
        guard recoveryInstance == nil else {
            completion(false)
            return
        }
        
        let navigationController = NavigationController()
        let flowController = createFlowController(phase: phase, keystoreProvider: storeProvider, navigationController: navigationController)
        let dismissItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissFlowCanceled))
        flowController.entryViewController.navigationItem.leftBarButtonItem = dismissItem
        navigationController.viewControllers = [flowController.entryViewController]
        viewController.present(navigationController, animated: true)
        
        recoveryInstance = RecoveryInstance(presentationType: .presented, flowController: flowController, completion: completion)
        presentor = viewController
    }
    
    private func createFlowController(phase: RecoveryPhase, keystoreProvider: KeystoreProvider, navigationController: UINavigationController) -> FlowController {
        switch phase {
        case .backup:
            let controller = BackupFlowController(keystoreProvider: storeProvider, navigationController: navigationController)
            controller.delegate = self
            return controller
        case .restore:
            let controller = RestoreFlowController(keystoreProvider: storeProvider, navigationController: navigationController)
            controller.delegate = self
            return controller
        }
    }
}

// MARK: - Navigation

@available(iOS 9.0, *)
extension RecoveryManager {
    private func flowCompleted() {
        guard let recoveryInstance = recoveryInstance else {
            return
        }
        
        recoveryInstance.completion(true)
        
        switch recoveryInstance.presentationType {
        case .presented:
            dismissFlow()
        case .pushed:
            popNavigationStackIfNeeded()
        }
        
        self.recoveryInstance = nil
    }
    
    private func dismissFlow() {
        presentor?.dismiss(animated: true)
    }
    
    @objc private func dismissFlowCanceled() {
        guard let recoveryInstance = recoveryInstance else {
            return
        }
        
        recoveryInstance.completion(false)
        dismissFlow()
    }
    
    private func popNavigationStackIfNeeded() {
        guard let flowController = recoveryInstance?.flowController else {
            return
        }
        
        let navigationController = flowController.navigationController
        let entryViewController = flowController.entryViewController
        
        guard let index = navigationController.viewControllers.index(of: entryViewController) else {
            return
        }
        
        if index > 0 {
            let externalViewController = navigationController.viewControllers[index - 1]
            navigationController.popToViewController(externalViewController, animated: true)
        }
    }
}

// MARK: - Flow

@available(iOS 9.0, *)
extension RecoveryManager: BackupFlowControllerDelegate {
    func backupFlowControllerQRString(_ controller: BackupFlowController) -> String {
        return "sample string"
    }
    
    func backupFlowControllerDidComplete(_ controller: BackupFlowController) {
        flowCompleted()
    }
}

@available(iOS 9.0, *)
extension RecoveryManager: RestoreFlowControllerDelegate {
    func restoreFlowControllerDidComplete(_ controller: RestoreFlowController) {
        flowCompleted()
    }
}

//extension UINavigationController {
//    open override var preferredStatusBarStyle: UIStatusBarStyle {
//        return super.preferredStatusBarStyle
//    }
//}
