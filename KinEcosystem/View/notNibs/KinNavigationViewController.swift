//
//  KinNavigationViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
class KinNavigationChildController : KinViewController {
    weak var kinNavigationController: KinNavigationViewController?
}

@available(iOS 9.0, *)
class KinNavigationViewController: KinViewController, UINavigationBarDelegate, UIGestureRecognizerDelegate {

    var core: Core! {
        didSet {
            balanceViewController.core = core
        }
    }

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var barBackground: UIImageView!
    @IBOutlet weak var balanceViewContainer: UIView!

    fileprivate let transitionController = UIViewController()
    fileprivate var rootViewController: KinNavigationChildController!
    fileprivate var viewDidLoadBlock: (() -> ())?
    fileprivate var tapRecognizer: UITapGestureRecognizer!
    fileprivate let transitionDuration = TimeInterval(0.3)
    fileprivate var balanceViewController: BalanceViewController!

    var kinChildViewControllers: [KinNavigationChildController] {
        return transitionController.childViewControllers as! [KinNavigationChildController]
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var edgesForExtendedLayout: UIRectEdge {
        get { return [] }
        set { super.edgesForExtendedLayout = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarAppearance()
        setupTransitionController()
        setupBalanceView()
        push(rootViewController, animated: false)
        viewDidLoadBlock?()
    }

    convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, rootViewController: KinNavigationChildController) {
        self.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.rootViewController = rootViewController
        self.balanceViewController = BalanceViewController(nibName: "BalanceViewController", bundle: Bundle.ecosystem)
    }

    fileprivate func setupNavigationBarAppearance() {
        navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationBar.isTranslucent = true
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        let backImage = UIImage(named: "back", in: Bundle.ecosystem, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal)
        navigationBar.backIndicatorImage = backImage
        navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationBar.delegate = self
        let colors = [UIColor.kinAzure, UIColor.kinBrightBlueTwo]
        barBackground.image = UINavigationBar.gradient(size: barBackground.bounds.size, colors: colors)
    }

    fileprivate func setupTransitionController() {
        transitionController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transitionController.view)
        transitionController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        transitionController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        transitionController.view.topAnchor.constraint(equalTo: balanceViewContainer.bottomAnchor).isActive = true
        transitionController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    fileprivate func setupBalanceView() {
        balanceViewContainer.addSubview(balanceViewController.view)
        balanceViewController.view.fillSuperview()
        balanceViewController.view.layoutIfNeeded()
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(balanceTapped(sender:)))
        tapRecognizer.delegate = self
        balanceViewController.view.addGestureRecognizer(tapRecognizer)
    }

    @objc fileprivate func balanceTapped(sender: UIGestureRecognizer) {
        transitionToOrders()
    }

    func transitionToOrders() {
        guard (kinChildViewControllers.last is OrdersViewController) == false else {
            return
        }
        Kin.track { try BalanceTapped() }
        let ordersController = OrdersViewController(nibName: "OrdersViewController", bundle: Bundle.ecosystem)
        ordersController.core = core
        push(ordersController, animated: true)
    }

    func push(_ viewController: KinNavigationChildController, animated: Bool, completion: (() -> Void)? = nil) {

        guard isViewLoaded else {
            viewDidLoadBlock = { [weak self] in
                self?.push(viewController, animated: animated)
            }
            return
        }

        guard let container = transitionController.view else { return }

        let shiftLeft = CGAffineTransform(translationX: -container.bounds.width, y: 0.0)
        let rightFrame = CGRect(x: container.bounds.width, y: 0.0, width: container.bounds.width, height: container.bounds.height)
        let p = rightFrame.origin.applying(shiftLeft)
        let frame = CGRect(origin: p, size: rightFrame.size)
        let leftFrame = CGRect(origin: frame.origin.applying(shiftLeft), size: rightFrame.size)

        viewController.view.frame = animated ? rightFrame : frame
        viewController.beginAppearanceTransition(true, animated: animated)
        container.addSubview(viewController.view)
        let outController = kinChildViewControllers.last

        let outView = outController?.view

        if viewController == rootViewController {
            navigationBar.items = [rootViewController.navigationItem]
        } else {
            navigationBar.pushItem(viewController.navigationItem, animated: animated)
        }


        outController?.beginAppearanceTransition(false, animated: animated)

        transitionController.addChildViewController(viewController)
        viewController.kinNavigationController = self

        balanceViewController.setSelected(viewController is OrdersViewController, animated: animated)

        guard animated else {
            outView?.removeFromSuperview()
            viewController.view.frame = frame
            viewController.didMove(toParentViewController: transitionController)
            viewController.endAppearanceTransition()
            outController?.endAppearanceTransition()
            completion?()
            return
        }

        tapRecognizer.isEnabled = false

        UIView.animate(withDuration: transitionDuration,
                       delay: 0.0,
                       options: [.curveEaseOut],
                       animations: {
            viewController.view.frame = frame
            outView?.frame = leftFrame
        }, completion: { (finished) in
            outView?.removeFromSuperview()
            viewController.didMove(toParentViewController: self.transitionController)
            self.tapRecognizer.isEnabled = true
            viewController.endAppearanceTransition()
            outController?.endAppearanceTransition()
            completion?()
        })

    }

    func popViewController(animated: Bool, completion: (() -> Void)? = nil) {
        let count = kinChildViewControllers.count
        guard   count > 1,
            let container = transitionController.view,
            let outController = kinChildViewControllers.last,
            let outView = outController.view,
            let inView = kinChildViewControllers[count - 2].view else {
            completion?()
            return
        }


        let inController = kinChildViewControllers[count - 2]
        let shiftLeft = CGAffineTransform(translationX: -container.bounds.width, y: 0.0)
        let rightFrame = CGRect(x: container.bounds.width, y: 0.0, width: container.bounds.width, height: container.bounds.height)
        let p = rightFrame.origin.applying(shiftLeft)
        let frame = CGRect(origin: p, size: rightFrame.size)
        let leftFrame = CGRect(origin: frame.origin.applying(shiftLeft), size: rightFrame.size)

        inController.beginAppearanceTransition(true, animated: animated)
        outController.beginAppearanceTransition(false, animated: animated)

        inView.frame = leftFrame
        container.addSubview(inView)

        balanceViewController.setSelected(inController is OrdersViewController, animated: animated)

        guard animated else {
            inView.frame = frame
            outView.removeFromSuperview()
            outController.willMove(toParentViewController: nil)
            outController.removeFromParentViewController()
            inController.endAppearanceTransition()
            outController.endAppearanceTransition()
            completion?()
            return
        }

        tapRecognizer.isEnabled = false

        UIView.animate(withDuration: transitionDuration,
                       delay: 0.0,
                       options: [.curveEaseOut],
                       animations: {
            inView.frame = frame
            outView.frame = rightFrame
        }, completion: { (finished) in
            outView.removeFromSuperview()
            outController.willMove(toParentViewController: nil)
            outController.removeFromParentViewController()
            inController.endAppearanceTransition()
            outController.endAppearanceTransition()
            self.tapRecognizer.isEnabled = true
            completion?()
        })
    }

    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        popViewController(animated: true)
        return true
    }

}
