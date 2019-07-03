//
//  KinAmountButton.swift
//  KinAppreciationModuleOptionsMenu
//
//  Created by Corey Werner on 19/06/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import UIKit

class KinAmountButton: UIButton {
    var theme: Theme = .light {
        didSet {
            updateTheme()
        }
    }

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let image = UIImage(named: "Kin", in: .appreciation, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        setImage(image, for: .normal)

        adjustsImageWhenHighlighted = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var imageEdgeInsets = self.imageEdgeInsets
        imageEdgeInsets.bottom = ((titleLabel?.bounds.size.height ?? 0) - (imageView?.image?.size.height ?? 0)) / 4
        self.imageEdgeInsets = imageEdgeInsets
    }

    override var isEnabled: Bool {
        didSet {
            imageView?.tintColor = titleColor(for: isEnabled ? .normal : .disabled)
        }
    }
}

// MARK: - Theme

extension KinAmountButton: ThemeProtocol {
    func updateTheme() {
        imageView?.tintColor = titleColor(for: .normal)
    }
}
