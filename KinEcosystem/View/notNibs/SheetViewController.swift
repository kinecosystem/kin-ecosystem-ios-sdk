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

class SheetNavigationController: UINavigationController, SheetPresented, Themed {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = false
        }
        setUpTheming()
    }
    
}

extension SheetViewController {
    
    func applyTheme(_ theme: Theme) {
        view.backgroundColor = theme.viewControllerColor
    }
    
}

extension SheetNavigationController {
    
    func applyTheme(_ theme: Theme) {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        navigationBar.titleTextAttributes = theme.title20.attributes
        view.backgroundColor = theme.viewControllerColor
    }
    
}


