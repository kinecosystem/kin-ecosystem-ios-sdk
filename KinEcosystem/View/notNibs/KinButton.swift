//
//  KinButton.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/05/2019.
//

import Foundation
import KinMigrationModule

enum KinButtonType {
    case purple
    case tealish
}

class KinButton: UIButton {
    
    
    var didSetupTheme = false
    fileprivate var type_: KinButtonType = .purple
    
    var type: KinButtonType {
        get {
            return type_
        }
        set {
            type_ = newValue
            setupTheming_()
        }
    }
    
    let themeLinkBag = LinkBag()
    
    var enabledColor: UIColor = .clear
    var disabledColor: UIColor = .clear
    var highlightedColor: UIColor = .clear
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        layer.masksToBounds = true
        setupTheming_()
    }
    
    func setupTheming_() {
        guard didSetupTheme == false else {
            return
        }
        didSetupTheme = true
        setupTheming()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 5.0
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 50
        return size
    }
    
    override var isEnabled: Bool {
        didSet {
            self.backgroundColor = isEnabled ? enabledColor : disabledColor
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? highlightedColor : enabledColor
        }
    }
}


extension KinButton: Themed {
    func applyTheme(_ theme: Theme) {
        switch type {
        case .purple:
            enabledColor = theme.purpleButtonEnabledColor
            disabledColor = theme.purpleButtonDisabledColor
            highlightedColor = theme.purpleButtonHighlightedColor
        case .tealish:
            enabledColor = theme.greenButtonEnabledColor
            disabledColor = theme.greenButtonDisabledColor
            highlightedColor = theme.greenButtonHighlightedColor
        }
        backgroundColor = isEnabled ? enabledColor : disabledColor
    }
}
