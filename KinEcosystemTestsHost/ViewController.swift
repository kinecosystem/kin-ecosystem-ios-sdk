//
//  ViewController.swift
//  KinEcosystemTestsHost
//
//  Created by Elazar Yifrach on 12/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinEcosystem

class ViewController: UIViewController {
    let brManager = BRManager(with: Kin.shared)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func createButton(_ title: String) -> UIButton {
            let button = UIButton()
            button.backgroundColor = .lightGray
            button.setTitle(title, for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            button.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button)
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            return button
        }
        
        let backupButton = createButton("Backup")
        backupButton.addTarget(self, action: #selector(backupAction), for: .touchUpInside)
        backupButton.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: -10).isActive = true
        
        let restoreButton = createButton("Restore")
        restoreButton.addTarget(self, action: #selector(restoreAction), for: .touchUpInside)
        restoreButton.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 10).isActive = true
    }

    @objc private func backupAction() {
        perform(phase: .backup)
    }
    
    @objc private func restoreAction() {
        perform(phase: .restore)
    }
    
    private func perform(phase: BRPhase) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Present", style: .default, handler: { _ in
            self.brManager.start(phase, presentedOn: self, events: { _ in
                
            }) { _ in
                
            }
        }))
        alertController.addAction(UIAlertAction(title: "Push on empty stack", style: .default, handler: { _ in
            let nc = UINavigationController()
            nc.view.backgroundColor = .yellow
            self.present(nc, animated: true) {
                self.brManager.start(phase, pushedOnto: nc, events: { _ in
                    
                }) { _ in
                    
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Push on existing stack", style: .default, handler: { _ in
            let vc = UIViewController()
            vc.view.backgroundColor = .green
            let nc = UINavigationController(rootViewController: vc)
            nc.view.backgroundColor = .yellow
            self.present(nc, animated: true) {
                self.brManager.start(phase, pushedOnto: nc, events: { _ in
                    
                }) { _ in
                    
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
}

