//
//  BackupFlowController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 23/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
protocol BackupFlowControllerDelegate: NSObjectProtocol {
    func backupFlowControllerDidComplete(_ controller: BackupFlowController)
}

@available(iOS 9.0, *)
class BackupFlowController: FlowController {
    weak var delegate: BackupFlowControllerDelegate?
    
    private lazy var _entryViewController: UIViewController = {
        let viewController = BackupIntroViewController()
        viewController.lifeCycleDelegate = self
        viewController.continueButton.addTarget(self, action: #selector(pushPasswordViewController), for: .touchUpInside)
        return viewController
    }()
    
    override var entryViewController: UIViewController {
        return _entryViewController
    }
}

@available(iOS 9.0, *)
extension BackupFlowController: LifeCycleProtocol {
    func viewController(_ viewController: UIViewController, willAppear animated: Bool) {
        syncNavigationBarColor(with: viewController)
    }
}

// MARK: - Navigation

@available(iOS 9.0, *)
extension BackupFlowController {
    @objc private func pushPasswordViewController() {
        let viewController = PasswordEntryViewController(nibName: "PasswordEntryViewController",
                                                                 bundle: Bundle.ecosystem)
        viewController.delegate = self
        viewController.lifeCycleDelegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    @objc private func pushQRViewController(with qrString: String) {
        let viewController = QRViewController(qrString: qrString)
        viewController.lifeCycleDelegate = self
        viewController.continueButton.addTarget(self, action: #selector(pushCompletedViewController), for: .touchUpInside)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    @objc private func pushCompletedViewController() {
        let viewController = BackupCompletedViewController()
        viewController.lifeCycleDelegate = self
        viewController.continueButton.addTarget(self, action: #selector(completedFlow), for: .touchUpInside)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    @objc private func completedFlow() {
        delegate?.backupFlowControllerDidComplete(self)
    }
}

// MARK: - Password

@available(iOS 9.0, *)
extension BackupFlowController: PasswordEntryDelegate {
    func validatePasswordConformance(_ password: String) -> Bool {
        return keystoreProvider.validatePassword(password)
    }
    
    func passwordEntryViewControllerDidComplete(_ viewController: PasswordEntryViewController) {
        guard let password = viewController.password else {
            return
        }
        
        do {
            pushQRViewController(with: try keystoreProvider.exportAccount(password))
        }
        catch {
            print(error)
        }
    }
}
