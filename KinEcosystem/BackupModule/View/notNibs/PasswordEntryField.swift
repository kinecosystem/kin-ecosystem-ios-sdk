//
//  PasswordEntryField.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 24/10/2018.
//

import UIKit

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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        revealIcon.addTarget(self, action: #selector(revealPassword), for: .touchDown)
        revealIcon.addTarget(self, action: #selector(hidePassword), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        revealIcon.contentMode = .topLeft
        revealIcon.setImage(UIImage(named: "greyRevealIcon", in: KinBundle.ecosystem.rawValue, compatibleWith: nil), for: .normal)
        revealIcon.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: -15.0, bottom: 0.0, right: 0.0)
        layer.cornerRadius = bounds.height / 2
        let paddingView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 22.0, height: frame.height))
        UIView.performWithoutAnimation {
            rightView = revealIcon
            rightViewMode = .whileEditing
            rightView?.frame = rightViewRect(forBounds: bounds)
        }
        layer.borderWidth = 1.0
        leftView = paddingView
        leftViewMode = .always
        isSecureTextEntry = true
        updateFieldStateStyle()
    }
    
    private func updateFieldStateStyle() {
        switch entryState {
        case .idle:
            layer.borderColor = UIColor.kinBlueGreyTwo.cgColor
        case .valid:
            layer.borderColor = UIColor.kinPrimaryBlue.cgColor
        case .invalid:
            layer.borderColor = UIColor.kinWarning.cgColor
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
