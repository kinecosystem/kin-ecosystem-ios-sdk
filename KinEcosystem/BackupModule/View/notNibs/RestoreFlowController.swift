//
//  RestoreFlowController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 23/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
protocol RestoreFlowControllerDelegate: NSObjectProtocol {
    func restoreFlowControllerDidComplete(_ controller: RestoreFlowController)
}

@available(iOS 9.0, *)
class RestoreFlowController: FlowController {
    weak var delegate: RestoreFlowControllerDelegate?
    
    private lazy var _entryViewController: UIViewController = {
        return BackupIntroViewController()
    }()
    
    override var entryViewController: UIViewController {
        return _entryViewController
    }
}

// MARK: - Navigation

@available(iOS 9.0, *)
extension RestoreFlowController {
    
}
