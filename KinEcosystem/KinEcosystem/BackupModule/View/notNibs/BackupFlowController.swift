//
//  BackupFlowController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 23/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class BackupFlowController: FlowController {
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

extension BackupFlowController: LifeCycleProtocol {
    func viewController(_ viewController: UIViewController, willAppear animated: Bool) {

    }
    
    func viewController(_ viewController: UIViewController, willDisappear animated: Bool) {
        cancelFlowIfNeeded(viewController)
    }
}

// MARK: - Navigation

extension BackupFlowController {
    @objc private func pushPasswordViewController() {
        Kin.track { try BackupStartButtonTapped() }
        let viewController = PasswordEntryViewController(nibName: "PasswordEntryViewController",
                                                                 bundle: KinBundle.ecosystem.rawValue)
        viewController.title = "kinecosystem_create_password".localized()
        viewController.navigationItem.rightBarButtonItem = ThemedLabelBarButtonItem(text: "1/2")
        viewController.delegate = self
        viewController.lifeCycleDelegate = self
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    @objc private func pushQRViewController(with qrString: String) {
        let viewController = QRViewController(qrString: qrString)
        viewController.title = "kinecosystem_backup_qr_title".localized()
        viewController.navigationItem.rightBarButtonItem = ThemedLabelBarButtonItem(text: "2/2")
        viewController.lifeCycleDelegate = self
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    @objc private func pushCompletedViewController() {
        let viewController = BackupCompletedViewController()
        viewController.lifeCycleDelegate = self
        viewController.navigationItem.hidesBackButton = true
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(completedFlow))
        navigationController.pushViewController(viewController, animated: true)
    }
    
    @objc private func completedFlow() {
        delegate?.flowControllerDidComplete(self)
    }
}

// MARK: - Password

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

extension BackupFlowController: QRViewControllerDelegate {
    func QRViewControllerDidComplete() {
        pushCompletedViewController()
    }
}
