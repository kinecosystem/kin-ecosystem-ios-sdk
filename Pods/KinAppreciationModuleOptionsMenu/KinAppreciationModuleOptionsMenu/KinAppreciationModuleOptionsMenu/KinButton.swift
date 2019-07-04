//
//  KinButton.swift
//  KinAppreciationModuleOptionsMenu
//
//  Created by Corey Werner on 19/06/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import UIKit

protocol KinButtonDelegate: NSObjectProtocol {
    func kinButtonDidFill(_ button: KinButton)
}

class KinButton: UIControl {
    weak var delegate: KinButtonDelegate?

    var theme: Theme = .light {
        didSet {
            updateTheme()
        }
    }

    private let fillContainerView = UIView()
    private let fillTitleLabel = UILabel()
    private var fillWidthConstraint: NSLayoutConstraint

    let titleLabel = UILabel()
    private var titles: [UInt: String?] = [:]
    private var titleColors: [UInt: UIColor?] = [:]

    var kin: Decimal = 0 {
        didSet {
            amountButton.setTitle("\(kin)", for: .normal)
        }
    }
    let amountButton = KinAmountButton()
    let amountButtonWidth: NSLayoutConstraint
    private var imageColors: [UInt: UIColor?] = [:]

    // MARK: Lifecycle

    override init(frame: CGRect) {
        fillWidthConstraint = fillContainerView.widthAnchor.constraint(equalToConstant: 0)
        fillWidthConstraint.isActive = true

        amountButtonWidth = amountButton.widthAnchor.constraint(equalToConstant: 0)

        super.init(frame: frame)

        titleLabel.font = .sailecFont(ofSize: 14)
        titleLabel.textAlignment = .center
        titleLabel.isUserInteractionEnabled = false
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        amountButton.titleLabel?.font = .sailecFont(ofSize: 20, weight: .medium)
        amountButton.isUserInteractionEnabled = false
        amountButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        addSubview(amountButton)
        amountButton.translatesAutoresizingMaskIntoConstraints = false
        amountButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        amountButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        amountButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true

        fillContainerView.clipsToBounds = true
        fillContainerView.isUserInteractionEnabled = false
        addSubview(fillContainerView)
        fillContainerView.translatesAutoresizingMaskIntoConstraints = false
        fillContainerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        fillContainerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        fillContainerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        fillTitleLabel.font = titleLabel.font
        fillTitleLabel.textAlignment = .center
        fillContainerView.addSubview(fillTitleLabel)
        fillTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        fillTitleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        fillTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        fillTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        fillTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        addTarget(self, action: #selector(fillAnimation), for: .touchUpInside)

        layer.borderWidth = 1
        layer.cornerRadius = 5
        layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow != nil {
            updateState()
        }
    }

    // MARK: Layout

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 46
        return size
    }
}

// MARK: - State

extension KinButton {
    override var isHighlighted: Bool {
        didSet {
            amountButton.isHighlighted = isHighlighted
            updateState()
        }
    }

    override var isSelected: Bool {
        didSet {
            amountButton.isSelected = isSelected
            updateState()
        }
    }

    override var isEnabled: Bool {
        didSet {
            amountButton.isEnabled = isEnabled
            updateState()
        }
    }

    private func updateState() {
        titleLabel.text = hierarchicalTitle(for: state)
        titleLabel.textColor = hierarchicalColor(for: state)
        fillTitleLabel.text = titleLabel.text
    }

    private func nextHierarchicalState(_ state: State) -> State {
        switch state {
        case [.selected, .highlighted]:
            return .selected

        default:
            return .normal
        }
    }

    private func hierarchicalObject<T>(for state: State, function: (_ state: State) -> (T?)) -> T? {
        var state = state

        while state != .normal {
            if let title = function(state) {
                return title
            }

            state = nextHierarchicalState(state)
        }

        return function(.normal)
    }
}

// MARK: - Title Label

extension KinButton {
    // MARK: Title

    func setTitle(_ title: String?, for state: State) {
        titles[state.rawValue] = title
    }

    func title(for state: State) -> String? {
        return titles[state.rawValue] ?? nil
    }

    private func hierarchicalTitle(for state: State) -> String? {
        return hierarchicalObject(for: state) { title(for: $0) }
    }

    // MARK: Color

    func setTitleColor(_ color: UIColor, for state: State) {
        titleColors[state.rawValue] = color
    }

    func color(for state: State) -> UIColor? {
        return titleColors[state.rawValue] ?? nil
    }

    private func hierarchicalColor(for state: State) -> UIColor? {
        return hierarchicalObject(for: state) { color(for: $0) }
    }
}

// MARK: - Animations

extension KinButton {
    @objc private func fillAnimation() {
        guard fillWidthConstraint.constant != bounds.width else {
            return
        }

        fillWidthConstraint.constant = bounds.width

        UIView.animate(withDuration: 1, animations: {
            self.layoutIfNeeded()
        }) { [weak self] _ in
            guard let strongSelf = self else{
                return
            }

            strongSelf.thanksTitleAnimation()
            strongSelf.delegate?.kinButtonDidFill(strongSelf)
        }
    }

    private func thanksTitleAnimation() {
        UIView.animate(withDuration: 0.15, animations: { [weak self] in
            self?.fillTitleLabel.alpha = 0
        }) { [weak self] _ in
            self?.fillTitleLabel.text = "thanks".localized()

            UIView.animate(withDuration: 0.15, animations: {
                self?.fillTitleLabel.alpha = 1
            })
        }
    }
}

// MARK: - Theme

extension KinButton: ThemeProtocol {
    func updateTheme() {
        switch theme {
        case .light:
            layer.borderColor = UIColor.gray222.cgColor

            setTitleColor(.gray140, for: .normal)
            setTitleColor(.gray222, for: .disabled)

            amountButton.setTitleColor(.kinGreen, for: .normal)
            amountButton.setTitleColor(.gray222, for: .disabled)

            fillContainerView.backgroundColor = .kinGreen
            fillTitleLabel.textColor = .white

        case .dark:
            layer.borderColor = UIColor.gray88.cgColor

            setTitleColor(.gray140, for: .normal)
            setTitleColor(.gray51, for: .disabled)

            amountButton.setTitleColor(.kinGreen, for: .normal)
            amountButton.setTitleColor(.gray51, for: .disabled)

            fillContainerView.backgroundColor = .kinGreen
            fillTitleLabel.textColor = .white
        }

        amountButton.theme = theme
    }
}
