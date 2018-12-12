//
//  BackupRestore.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 15/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import KinUtil

public protocol KeystoreProvider {
    func exportAccount(_ password: String) throws -> String
    func importAccount(keystore: String, password: String, completion: @escaping (Error?) -> ())
    func validatePassword(_ password: String) -> Bool
}

public typealias BRCompletionHandler = (_ success: Bool) -> ()
public typealias BREventsHandler = (_ event: BREvent) -> ()

public enum BRPhase {
    case backup
    case restore
}

public enum BREvent {
    case backup(BREventType)
    case restore(BREventType)
}

public enum BREventType {
    case nextTapped
    case passwordMismatch
    case qrMailSent
}

private enum BRPresentationType {
    case pushed
    case presented
}

private struct BRInstance {
    let presentationType: BRPresentationType
    let flowController: FlowController
    let completion: BRCompletionHandler
}

@available(iOS 9.0, *)
public class BRManager: NSObject {
    private let storeProvider: KeystoreProvider
    private var presentor: UIViewController?
    private var brInstance: BRInstance?
    
    private var navigationBarBackgroundImages: [UIBarMetrics: UIImage?]?
    private var navigationBarShadowImage: UIImage?
    private var navigationBarTintColor: UIColor?
    
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
    public func start(_ phase: BRPhase,
                      pushedOnto navigationController: UINavigationController,
                      events: BREventsHandler,
                      completion: @escaping BRCompletionHandler)
    {
        guard brInstance == nil else {
            completion(false)
            return
        }
        
        let isStackEmpty = navigationController.viewControllers.isEmpty
        
        removeNavigationBarBackground(navigationController.navigationBar, shouldSave: !isStackEmpty)
        
        let flowController = createFlowController(phase: phase, keystoreProvider: storeProvider, navigationController: navigationController)
        navigationController.pushViewController(flowController.entryViewController, animated: !isStackEmpty)
        
        brInstance = BRInstance(presentationType: .pushed, flowController: flowController, completion: completion)
    }
    
    /**
     Start a backup or recovery phase by presenting the navigation controller onto a view controller.
     
     - Parameter phase: Perform a backup or restore
     - Parameter viewController: The view controller being presented onto
     - Parameter events:
     - Parameter completion:
     */
    public func start(_ phase: BRPhase,
                      presentedOn viewController: UIViewController,
                      events: BREventsHandler,
                      completion: @escaping BRCompletionHandler)
    {
        guard brInstance == nil else {
            completion(false)
            return
        }
        
        let navigationController = UINavigationController()
        removeNavigationBarBackground(navigationController.navigationBar)
        
        let flowController = createFlowController(phase: phase, keystoreProvider: storeProvider, navigationController: navigationController)
        let dismissItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: flowController, action: #selector(flowController.cancelFlow))
        flowController.entryViewController.navigationItem.leftBarButtonItem = dismissItem
        navigationController.viewControllers = [flowController.entryViewController]
        viewController.present(navigationController, animated: true)
        
        brInstance = BRInstance(presentationType: .presented, flowController: flowController, completion: completion)
        presentor = viewController
    }
    
    private func createFlowController(phase: BRPhase, keystoreProvider: KeystoreProvider, navigationController: UINavigationController) -> FlowController {
        let controller: FlowController
        
        switch phase {
        case .backup:
            controller = BackupFlowController(keystoreProvider: storeProvider, navigationController: navigationController)
        case .restore:
            controller = RestoreFlowController(keystoreProvider: storeProvider, navigationController: navigationController)
        }
        
        controller.delegate = self
        return controller
    }
}

// MARK: - Navigation

@available(iOS 9.0, *)
extension BRManager {
    private var navigationController: UINavigationController? {
        return brInstance?.flowController.navigationController
    }
    
    private func dismissFlow() {
        presentor?.dismiss(animated: true)
    }
    
    private func popNavigationStackIfNeeded() {
        guard let flowController = brInstance?.flowController else {
            return
        }
        
        let navigationController = flowController.navigationController
        let entryViewController = flowController.entryViewController
        
        guard let index = navigationController.viewControllers.index(of: entryViewController) else {
            return
        }
        
        if index > 0 {
            restoreNavigationBarBackground(navigationController.navigationBar)
            
            let externalViewController = navigationController.viewControllers[index - 1]
            navigationController.popToViewController(externalViewController, animated: true)
        }
    }
}

// MARK: - Flow

@available(iOS 9.0, *)
extension BRManager: FlowControllerDelegate {
    func flowControllerDidComplete(_ controller: FlowController) {
        guard let brInstance = brInstance else {
            return
        }
        
        brInstance.completion(true)
        
        switch brInstance.presentationType {
        case .presented:
            dismissFlow()
        case .pushed:
            popNavigationStackIfNeeded()
        }
        
        self.brInstance = nil
    }
    
    func flowControllerDidCancel(_ controller: FlowController) {
        guard let brInstance = brInstance else {
            return
        }
        
        brInstance.completion(false)
        
        switch brInstance.presentationType {
        case .presented:
            dismissFlow()
        case .pushed:
            if let navigationController = navigationController {
                restoreNavigationBarBackground(navigationController.navigationBar)
            }
        }
        
        self.brInstance = nil
    }
}

// MARK: - Navigation Bar Appearance

@available(iOS 9.0, *)
extension BRManager {
    private func removeNavigationBarBackground(_ navigationBar: UINavigationBar, shouldSave: Bool = false) {
        if shouldSave {
            let barMetrics: [UIBarMetrics] = [.default, .defaultPrompt, .compact, .compactPrompt]
            var navigationBarBackgroundImages = [UIBarMetrics: UIImage?]()
            
            for barMetric in barMetrics {
                navigationBarBackgroundImages[barMetric] = navigationBar.backgroundImage(for: barMetric)
            }
            
            if !navigationBarBackgroundImages.isEmpty {
                self.navigationBarBackgroundImages = navigationBarBackgroundImages
            }
            
            navigationBarShadowImage = navigationBar.shadowImage
            navigationBarTintColor = navigationBar.tintColor
        }
        
        navigationBar.removeBackground()
    }
    
    private func restoreNavigationBarBackground(_ navigationBar: UINavigationBar) {
        navigationBar.restoreBackground(backgroundImages: navigationBarBackgroundImages, shadowImage: navigationBarShadowImage)
        navigationBar.tintColor = navigationBarTintColor
        
        navigationBarBackgroundImages = nil
        navigationBarShadowImage = nil
        navigationBarTintColor = nil
    }
}
