//
//  PasswordEntryField.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 24/10/2018.
//

import UIKit
import KinUtil

public enum PasswordEntryFieldState {
    case idle
    case valid
    case invalid
}

@available(iOS 9.0, *)
class PasswordEntryField: UITextField {
    public var entryState = PasswordEntryFieldState.idle {
        didSet {
            updateFieldStateStyle()
        }
    }
    
    private let revealIcon = UIButton(37.0, 15.0)
    let themeLinkBag = LinkBag()
    var theme: Theme?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        setupTheming()
        revealIcon.addTarget(self, action: #selector(revealPassword), for: .touchDown)
        revealIcon.addTarget(self, action: #selector(hidePassword), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        revealIcon.contentMode = .topLeft
        revealIcon.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: -15.0, bottom: 0.0, right: 0.0)
        let paddingView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 22.0, height: frame.height))
        UIView.performWithoutAnimation {
            rightView = revealIcon
            rightViewMode = .whileEditing
            rightView?.frame = rightViewRect(forBounds: bounds)
        }
        layer.cornerRadius = 2
        layer.borderWidth = 1.0
        leftView = paddingView
        leftViewMode = .always
        isSecureTextEntry = true
        updateFieldStateStyle()
    }
    
    private func updateFieldStateStyle() {
        let theme = self.theme ?? .light

        switch entryState {
        case .idle:
            layer.borderColor = theme.textFieldIdle.cgColor
        case .valid:
            layer.borderColor = theme.textFieldValid.cgColor
        case .invalid:
            layer.borderColor = theme.textFieldInvalid.cgColor
        }
    }
    
    @objc private func revealPassword(_ sender: Any) {
        secureButtonHandler(false)
    }
    
    @objc private func hidePassword(_ sender: Any) {
        secureButtonHandler(true)
    }
    
    private func secureButtonHandler(_ secure: Bool) {
        let isFirst = isFirstResponder
        if isFirst {
            resignFirstResponder()
        }
        isSecureTextEntry = secure
        if isFirst {
            becomeFirstResponder()
        }
    }
}

extension PasswordEntryField: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme

        let revealImage = UIImage(named: "revealIcon", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        revealIcon.setImage(revealImage,
                            for: .normal)
        updateFieldStateStyle()
    }
}
