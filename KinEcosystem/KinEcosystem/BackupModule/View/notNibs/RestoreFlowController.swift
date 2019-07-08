//
//  RestoreFlowController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 23/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class RestoreFlowController: FlowController {
    private var qrPickerController: QRPickerController?
    
    private lazy var _entryViewController: UIViewController = {
        let viewController = RestoreIntroViewController()
        viewController.navigationItem.rightBarButtonItem = ThemedLabelBarButtonItem(text: "1/2")
        viewController.delegate = self
        viewController.lifeCycleDelegate = self
        return viewController
    }()
    
    override var entryViewController: UIViewController {
        return _entryViewController
    }
}

extension RestoreFlowController: LifeCycleProtocol {
    func viewController(_ viewController: UIViewController, willAppear animated: Bool) {

    }
    
    func viewController(_ viewController: UIViewController, willDisappear animated: Bool) {
        cancelFlowIfNeeded(viewController)
    }
}

// MARK: - Navigation

extension RestoreFlowController {
    private func presentQRPickerViewController() {
        guard QRPickerController.canOpenImagePicker else {
            // TODO: how to deal with this case?
            // why would the users device not allow for image picker presentation and
            // is there a way to circumvent this path?
            return
        }
        
        let qrPickerController = QRPickerController()
        qrPickerController.delegate = self
        navigationController.present(qrPickerController.imagePickerController, animated: true)
        self.qrPickerController = qrPickerController
    }
    
    private func pushPasswordViewController(with qrString: String) {
        let restoreViewController = RestoreViewController()
        restoreViewController.navigationItem.rightBarButtonItem = ThemedLabelBarButtonItem(text: "2/2")
        restoreViewController.delegate = self
        restoreViewController.lifeCycleDelegate = self
        restoreViewController.imageView.image = QR.generateImage(from: qrString)
        navigationController.pushViewController(restoreViewController, animated: true)
    }
}

// MARK: - Flow

extension RestoreFlowController: RestoreIntroViewControllerDelegate {
    func restoreIntroViewControllerDidComplete(_ viewController: RestoreIntroViewController) {
        presentQRPickerViewController()
    }
}

extension RestoreFlowController: QRPickerControllerDelegate {
    func qrPickerControllerDidComplete(_ controller: QRPickerController, with qrString: String?) {
        controller.imagePickerController.presentingViewController?.dismiss(animated: true)
        
        if let qrString = qrString {
            pushPasswordViewController(with: qrString)
        }
    }
}

extension RestoreFlowController: RestoreViewControllerDelegate {
    func restoreViewControllerDidImport(_ viewController: RestoreViewController, completion:@escaping (RestoreViewController.ImportResult) -> ()) {
        guard let password = viewController.password else {
            completion(.wrongPassword)
            return
        }
        guard let qrImage = viewController.imageView.image, let keystore = QR.decode(image: qrImage) else {
            completion(.invalidImage)
            return
        }
        
        keystoreProvider.importAccount(keystore: keystore, password: password) { error in
            if let error = error {
                if case KinEcosystemError.blockchain(.invalidPassword, _) = error {
                    completion(.wrongPassword)
                } else {
                    completion(.internalIssue)
                }
            } else {
                completion(.success)
            }
        }
        
    }
    
    func restoreViewControllerDidComplete(_ viewController: RestoreViewController) {
        // Delay to prevent a jarring jump after the checkmark animation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.delegate?.flowControllerDidComplete(strongSelf)
        }
    }
}
