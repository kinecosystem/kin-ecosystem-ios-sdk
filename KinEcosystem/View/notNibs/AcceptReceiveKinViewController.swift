//
//  AcceptReceiveKinViewController.swift
//  KinEcosystem
//
//  Created by Natan Rolnik on 07/02/19.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit
import MoveKin

private func messageText(for sourceApp: String) -> String {
    let thisApp = Bundle.appName ?? "kinecosystem_thisapp".localized()
    return "kinecosystem_move_kin_accept_message".localized(sourceApp, thisApp)
}

@available(iOS 9.0, *)
class AcceptReceiveKinViewController: UIViewController {
    var appName: String = ""
    var acceptHandler: (() -> Void)?
    var cancelHandler: (() -> Void)?

    let messageLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 0
        l.font = UIFont.systemFont(ofSize: 16)

        return l
    }()

    let acceptButton: UIButton = {
        let b = RoundButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("kinecosystem_move_kin_accept_button_title".localized(), for: .normal)
        b.widthAnchor.constraint(equalToConstant: 280).isActive = true
        b.heightAnchor.constraint(equalToConstant: 50).isActive = true
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .kinPrimaryBlue

        return b
    }()

    let kinImageView = UIImageView(image: UIImage(named: "KinEcosystemLogo", in: Bundle.ecosystem, compatibleWith: nil))

    override func loadView() {
        let v = UIView()
        v.backgroundColor = .white

        let stackView = UIStackView(arrangedSubviews: [kinImageView, messageLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.distribution = .fillProportionally

        v.addSubview(stackView)
        let yConstraint = NSLayoutConstraint(item: stackView,
                                             attribute: .centerY,
                                             relatedBy: .equal,
                                             toItem: v,
                                             attribute: .centerY,
                                             multiplier: 0.75,
                                             constant: 0)
        NSLayoutConstraint.activate([stackView.centerXAnchor.constraint(equalTo: v.centerXAnchor),
                                     yConstraint,
                                     stackView.widthAnchor.constraint(equalToConstant: 280)])

        v.addSubview(acceptButton)
        acceptButton.tintColor = .white
        v.centerXAnchor.constraint(equalTo: acceptButton.centerXAnchor).isActive = true
        v.bottomAnchor.constraint(equalTo: acceptButton.bottomAnchor, constant: 90).isActive = true

        view = v
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Kin Ecosystem"
        let closeImage = UIImage(named: "closeIcon", in: Bundle.ecosystem, compatibleWith: nil)?
            .withRenderingMode(.alwaysTemplate)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: closeImage,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(cancel))
        navigationItem.leftBarButtonItem?.tintColor = .black
        messageLabel.text = messageText(for: appName)
        acceptButton.addTarget(self, action: #selector(accept), for: .touchUpInside)
    }

    @objc func cancel() {
        cancelHandler?()
    }

    @objc func accept() {
        acceptHandler?()
    }
}

@available(iOS 9.0, *)
extension AcceptReceiveKinViewController: AcceptReceiveKinPage {
    func setupAcceptReceiveKinPage(cancelHandler: @escaping () -> Void, acceptHandler: @escaping () -> Void) {
        self.acceptHandler = acceptHandler
        self.cancelHandler = cancelHandler
    }
}
