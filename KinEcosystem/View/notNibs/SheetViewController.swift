//
//  SheetViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 20/05/2019.
//

import KinMigrationModule

protocol SheetPresented: UIViewController, UIViewControllerTransitioningDelegate {
    var cover: SheetTransitionCover { get }
}

class SheetViewController: UIViewController, SheetPresented, Themed {
    
    var themeLinkBag = LinkBag()
    var cover: SheetTransitionCover = .half
    
    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get { return self }
        set { }
    }
    override var modalPresentationStyle: UIModalPresentationStyle {
        get{
            return .custom
        }
        set {}
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = SheetPresentationController(presentedViewController: presented, presenting: presenting)
        controller.cover = cover
        return controller
    }
    
}

class SheetNavigationControllerWrapper: UIViewController, SheetPresented, Themed {
    
    var themeLinkBag = LinkBag()
    var cover: SheetTransitionCover = .half
    
    let wrappedNavigationController: UINavigationController
    
    init() {
        wrappedNavigationController = UINavigationController(nibName: nil, bundle: nil)
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    init(rootViewController: UIViewController) {
        wrappedNavigationController = UINavigationController(rootViewController: rootViewController)
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    func commonInit() {
        loadViewIfNeeded()
    }
    
    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get { return self }
        set { }
    }
    override var modalPresentationStyle: UIModalPresentationStyle {
        get{
            return .custom
        }
        set {}
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = SheetPresentationController(presentedViewController: presented, presenting: presenting)
        controller.cover = cover
        return controller
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        wrappedNavigationController.loadViewIfNeeded()
        wrappedNavigationController.willMove(toParent: self)
        wrappedNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wrappedNavigationController.view)
        addChild(wrappedNavigationController)
        wrappedNavigationController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            wrappedNavigationController.view.topAnchor.constraint(equalTo: bcSafeAreaLayoutGuide.topAnchor, constant: 16.0),
            wrappedNavigationController.view.leftAnchor.constraint(equalTo: bcSafeAreaLayoutGuide.leftAnchor, constant: 0.0),
            wrappedNavigationController.view.rightAnchor.constraint(equalTo: bcSafeAreaLayoutGuide.rightAnchor, constant: 0.0),
            wrappedNavigationController.view.bottomAnchor.constraint(equalTo: bcSafeAreaLayoutGuide.bottomAnchor, constant: 0.0)
            ])
        view.setNeedsLayout()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
    }
    
    
    
    func pushViewController(_ viewController: UIViewController, animated: Bool) {
        wrappedNavigationController.pushViewController(viewController, animated: animated)
    }
    
    func popViewController(_ viewController: UIViewController, animated: Bool) -> UIViewController? {
        return wrappedNavigationController.popViewController(animated: animated)
    }
    
}

extension SheetViewController {
    
    func applyTheme(_ theme: Theme) {
        view.backgroundColor = theme.viewControllerColor
    }
    
}

extension SheetNavigationControllerWrapper {
    
    func applyTheme(_ theme: Theme) {
        wrappedNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        wrappedNavigationController.navigationBar.shadowImage = UIImage()
        wrappedNavigationController.navigationBar.isTranslucent = true
        wrappedNavigationController.navigationBar.titleTextAttributes = theme.title20.attributes
        view.backgroundColor = theme.viewControllerColor
    }
    
}

extension UIViewController {
    
    var bcSafeAreaLayoutGuide: UILayoutGuide {
        if #available(iOS 11.0, *) {
            return view.safeAreaLayoutGuide
        } else {
            let id = "bcSafeAreaLayoutGuide"
            
            if let layoutGuide = view.layoutGuides.first(where: { $0.identifier == id }) {
                return layoutGuide
            } else {
                let layoutGuide = UILayoutGuide()
                layoutGuide.identifier = id
                view.addLayoutGuide(layoutGuide)
                layoutGuide.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
                layoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
                layoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
                layoutGuide.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
                return layoutGuide
            }
        }
    }
    
}

