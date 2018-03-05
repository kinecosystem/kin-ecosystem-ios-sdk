//
//  KinNavigationViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class KinNavigationChildController : UIViewController {
    weak var kinNavigationController: KinNavigationViewController?
}

class KinNavigationViewController: UIViewController, UINavigationBarDelegate, UIGestureRecognizerDelegate {
    
    var core: Core!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var balanceView: BalanceView!
    @IBOutlet weak var barBackground: UIImageView!
    
    fileprivate let transitionController = UIViewController()
    fileprivate var rootViewController: KinNavigationChildController!
    fileprivate var viewDidLoadBlock: (() -> ())?
    fileprivate var tapRecognizer: UITapGestureRecognizer!
    fileprivate let transitionDuration = TimeInterval(0.3)
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
        transitionController.view.topAnchor.constraint(equalTo: balanceView.bottomAnchor).isActive = true
        transitionController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    fileprivate func setupBalanceView() {
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(balanceTapped(sender:)))
        tapRecognizer.delegate = self
        balanceView.addGestureRecognizer(tapRecognizer)
    }
    
    @objc fileprivate func balanceTapped(sender: UIGestureRecognizer) {
        guard (transitionController.childViewControllers.last is OrdersViewController) == false else {
            return
        }
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
        container.addSubview(viewController.view)
        let outView = transitionController.childViewControllers.last?.view
        
        if viewController == rootViewController {
            navigationBar.items = [rootViewController.navigationItem]
        } else {
            navigationBar.pushItem(viewController.navigationItem, animated: animated)
        }
        
        transitionController.addChildViewController(viewController)
        viewController.kinNavigationController = self
        
        balanceView.setSelected(viewController is OrdersViewController, animated: animated)

        guard animated else {
            outView?.removeFromSuperview()
            viewController.didMove(toParentViewController: transitionController)
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
            completion?()
        })
        
    }
    
    func popViewController(animated: Bool, completion: (() -> Void)? = nil) {
        let count = transitionController.childViewControllers.count
        guard   count > 1,
            let container = transitionController.view,
            let outController = transitionController.childViewControllers.last,
            let outView = outController.view,
            let inView = transitionController.childViewControllers[count - 2].view else {
            completion?()
            return
        }
        
        let shiftLeft = CGAffineTransform(translationX: -container.bounds.width, y: 0.0)
        let rightFrame = CGRect(x: container.bounds.width, y: 0.0, width: container.bounds.width, height: container.bounds.height)
        let p = rightFrame.origin.applying(shiftLeft)
        let frame = CGRect(origin: p, size: rightFrame.size)
        let leftFrame = CGRect(origin: frame.origin.applying(shiftLeft), size: rightFrame.size)
        
        
        inView.frame = leftFrame
        container.addSubview(inView)
        
        balanceView.setSelected(transitionController.childViewControllers[count - 2] is OrdersViewController, animated: animated)
        
        guard animated else {
            inView.frame = frame
            outView.removeFromSuperview()
            outController.removeFromParentViewController()
            
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
            self.tapRecognizer.isEnabled = true
            completion?()
        })
    }
    
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        popViewController(animated: true)
        return true
    }
    
}

