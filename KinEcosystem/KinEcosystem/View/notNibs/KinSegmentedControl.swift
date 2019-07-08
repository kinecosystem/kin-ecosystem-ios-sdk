//
//  KinSegmentedControl.swift
//  KinEcosystem
//
//  Created by Natan Rolnik on 25/06/19.
//

import UIKit

class KinSegmentedControl: UIControl {
    private(set) var selectedSegmentIndex = 0 {
        didSet {
            if oldValue != selectedSegmentIndex {
                sendActions(for: .valueChanged)
                sendActions(for: .primaryActionTriggered)
            }
        }
    }

    private let leftButton = UIButton()
    private let rightButton = UIButton()

    @IBInspectable var leftItem: String? {
        didSet {
            leftButton.setTitle(leftItem, for: .normal)
        }
    }

    @IBInspectable var rightItem: String? {
        didSet {
            rightButton.setTitle(rightItem, for: .normal)
        }
    }

    init(leftItem: String, rightItem: String) {
        super.init(frame: .zero)

        commonInit()
        self.leftItem = leftItem
        self.rightItem = rightItem
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    func commonInit() {
        let leftUnselectedImage = UIImage(named: "KinSegControlUnselectedLeft", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        let leftSelectedImage = UIImage(named: "KinSegControlSelectedLeft", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)

        leftButton.isSelected = true
        leftButton.setBackgroundImage(leftUnselectedImage, for: .normal)
        leftButton.setBackgroundImage(leftSelectedImage, for: .highlighted)
        leftButton.setBackgroundImage(leftSelectedImage, for: .selected)

        let rightUnselectedImage = UIImage(named: "KinSegControlUnselectedRight", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        let rightSelectedImage = UIImage(named: "KinSegControlSelectedRight", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)

        rightButton.setBackgroundImage(rightUnselectedImage, for: .normal)
        rightButton.setBackgroundImage(rightSelectedImage, for: .highlighted)
        rightButton.setBackgroundImage(rightSelectedImage, for: .selected)
        rightButton.setTitle(rightItem, for: .normal)

        let stackView = UIStackView(arrangedSubviews: [leftButton, rightButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        addSubview(stackView)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            topAnchor.constraint(equalTo: stackView.topAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
            ])
        [leftButton, rightButton].forEach {
            $0.titleLabel?.font = TextStyle.segmentSelectedTitleAnyTheme.attributes[.font] as? UIFont
            $0.setTitleColor(TextStyle.segmentUnselectedTitleAnyTheme.attributes[.foregroundColor] as? UIColor, for: .normal)
            $0.setTitleColor(TextStyle.segmentSelectedTitleAnyTheme.attributes[.foregroundColor] as? UIColor, for: .highlighted)
            $0.setTitleColor(TextStyle.segmentSelectedTitleAnyTheme.attributes[.foregroundColor] as? UIColor, for: .selected)
            $0.addTarget(self, action: #selector(buttonTapped(_:)), for: .primaryActionTriggered)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 30)
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        sender.isSelected = true

        if sender == leftButton {
            selectedSegmentIndex = 0
            rightButton.isSelected = false
        } else if sender == rightButton {
            selectedSegmentIndex = 1
            leftButton.isSelected = false
        }
    }
}
