//
//  KinButton.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/05/2019.
//

import Foundation
import KinMigrationModule

class KinButton: UIButton {
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
        tintColor = .white
        layer.masksToBounds = true
        setupTheming()
        titleLabel?.font = Font(name: "Sailec-Medium", size: 16)
        setTitleColor(UIColor.KinNewUi.white, for: .normal)
        setTitleColor(UIColor.KinNewUi.brownGray, for: .disabled)
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
        enabledColor = theme.actionButtonEnabledColor
        disabledColor = theme.actionButtonDisabledColor
        highlightedColor = theme.actionButtonHighlightedColor

        backgroundColor = isEnabled ? enabledColor : disabledColor
    }
}
