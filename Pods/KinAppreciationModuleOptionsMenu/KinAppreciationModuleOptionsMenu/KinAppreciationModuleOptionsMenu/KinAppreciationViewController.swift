//
//  KinAppreciationViewController.swift
//  KinAppreciationModuleOptionsMenu
//
//  Created by Corey Werner on 17/06/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import UIKit

public protocol KinAppreciationViewControllerDelegate: NSObjectProtocol {
    func kinAppreciationViewControllerDidPresent(_ viewController: KinAppreciationViewController)
    func kinAppreciationViewController(_ viewController: KinAppreciationViewController, didDismissWith reason: KinAppreciationCancelReason)
    func kinAppreciationViewController(_ viewController: KinAppreciationViewController, didSelect amount: Decimal)
}

public class KinAppreciationViewController: UIViewController {
    public private(set) var balance: Decimal
    public let theme: Theme

    public weak var delegate: KinAppreciationViewControllerDelegate?
    public weak var biDelegate: KinAppreciationBIDelegate? {
        didSet {
            KinAppreciationBI.shared.delegate = biDelegate
        }
    }

    private var kButtons: [KinButton] = []

    private var cancelReason: KinAppreciationCancelReason = .hostApplication

    // MARK: View

    lazy var _view: KinAppreciationView = {
        return KinAppreciationView(frame: UIScreen.main.bounds)
    }()

    public override func loadView() {
        _view.theme = theme
        view = _view

        kButtons = [
            _view.k1Button,
            _view.k5Button,
            _view.k10Button,
            _view.k20Button
        ]
    }

    // MARK: Lifecycle

    public init(balance: Decimal, theme: Theme) {
        self.balance = balance
        self.theme = theme

        UIFont.custom.loadFontsIfNeeded()

        super.init(nibName: nil, bundle: nil)

        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        _view.closeButton.addTarget(self, action: #selector(xTappedAction), for: .touchUpInside)

        setAmountTitle()

        for kButton in kButtons {
            if kButton.kin > balance {
                kButton.isEnabled = false
            }
            else {
                kButton.delegate = self
                kButton.addTarget(self, action: #selector(kButtonAction(_:)), for: .touchUpInside)
            }
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        KinAppreciationBI.shared.delegate?.kinAppreciationDidAppear()

        delegate?.kinAppreciationViewControllerDidPresent(self)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        KinAppreciationBI.shared.delegate?.kinAppreciationDidCancel(reason: cancelReason)

        delegate?.kinAppreciationViewController(self, didDismissWith: cancelReason)
    }

    // MARK: Convenience

    private func setAmountTitle() {
        _view.amountButton.setTitle("\(balance)", for: .normal)
    }

    private var hasSelectedButton: Bool {
        return kButtons.first { $0.isSelected } != nil
    }
}

// MARK: - Actions

extension KinAppreciationViewController {
    @objc private func kButtonAction(_ button: KinButton) {
        guard !hasSelectedButton else {
            return
        }

        KinAppreciationBI.shared.delegate?.kinAppreciationDidSelect(amount: button.kin)

        button.isSelected = true

        for kButton in kButtons {
            if kButton != button {
                kButton.isEnabled = false
            }
        }

        delegate?.kinAppreciationViewController(self, didSelect: button.kin)
    }

    @objc private func xTappedAction() {
        guard !hasSelectedButton else {
            return
        }
        
        cancelReason = .closeButton

        presentingViewController?.dismiss(animated: true)
    }

    @objc private func backgroundTappedAction() {
        guard !hasSelectedButton else {
            return
        }

        cancelReason = .touchOutside

        presentingViewController?.dismiss(animated: true)
    }
}

// MARK: - Kin Button

extension KinAppreciationViewController: KinButtonDelegate {
    func kinButtonDidFill(_ button: KinButton) {
        balance -= button.kin
        setAmountTitle()

        button.superview?.bringSubviewToFront(button)

        let confettiView = ConfettiView(frame: button.bounds)
        confettiView.delegate = self
        confettiView.count = 30
        button.superview?.insertSubview(confettiView, belowSubview: button)
        confettiView.translatesAutoresizingMaskIntoConstraints = false
        confettiView.topAnchor.constraint(equalTo: button.topAnchor).isActive = true
        confettiView.leadingAnchor.constraint(equalTo: button.leadingAnchor).isActive = true
        confettiView.bottomAnchor.constraint(equalTo: button.bottomAnchor).isActive = true
        confettiView.trailingAnchor.constraint(equalTo: button.trailingAnchor).isActive = true
        confettiView.explodeAnimation()
    }
}

// MARK: - Transitioning Delegate

extension KinAppreciationViewController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = PresentationController(presentedViewController: presented, presenting: presenting)
        presentationController.tapGesture.addTarget(self, action: #selector(backgroundTappedAction))
        return presentationController
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AnimatedTransitioning(presenting: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AnimatedTransitioning(presenting: false)
    }
}

// MARK: - Confetti View

extension KinAppreciationViewController: ConfettiViewDelegate {
    func confettiViewDidComplete(_ confettiView: ConfettiView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.biDelegate?.kinAppreciationDidComplete()

            strongSelf.presentingViewController?.dismiss(animated: true)
        }
    }
}
