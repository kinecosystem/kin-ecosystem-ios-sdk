//
//  PresentationController.swift
//  KinAppreciationModuleOptionsMenu
//
//  Created by Corey Werner on 19/06/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import UIKit

class PresentationController: UIPresentationController {
    let tapGesture = UITapGestureRecognizer()

    lazy private var backgroundView: UIView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.frame = self.containerView?.bounds ?? .zero
        view.backgroundColor = nil
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView, let presentedView = presentedView else {
            return .zero
        }

        var rect = containerView.frame
        rect.size.height = presentedView.intrinsicContentSize.height
        rect.origin.y = containerView.bounds.height - rect.size.height
        return rect
    }

    var frameOfDismissedViewInContainerView: CGRect {
        guard let containerView = containerView, let presentedView = presentedView else {
            return .zero
        }

        var rect = containerView.frame
        rect.origin.y = rect.size.height
        rect.size.height = presentedView.bounds.height
        return rect
    }

    override func presentationTransitionWillBegin() {
        containerView?.addSubview(backgroundView)
        backgroundView.alpha = 0

        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.backgroundView.alpha = 1
        })
    }

    override func dismissalTransitionWillBegin() {
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.backgroundView.alpha = 0
        })
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            backgroundView.removeFromSuperview()
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            backgroundView.removeFromSuperview()
        }
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        if let presentedView = presentedView, presentedView.layer.mask == nil {
            let corners: UIRectCorner = [.topLeft, .topRight]
            let radius = 10
            let radii = CGSize(width: radius, height: radius)
            let bezierPath = UIBezierPath(roundedRect: presentedView.bounds, byRoundingCorners: corners, cornerRadii: radii)

            let mask = CAShapeLayer()
            mask.path = bezierPath.cgPath

            presentedView.layer.mask = mask
            presentedView.layer.masksToBounds = true
        }
    }
}
