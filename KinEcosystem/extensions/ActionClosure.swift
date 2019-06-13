//
//  ActionClosure.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 29/05/2019.
//

import Foundation
extension UIBarButtonItem {
    private struct AssociatedObject {
        static var key = "action_closure_key"
    }
    
    var actionClosure: (() -> ())? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObject.key) as? () -> ()
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObject.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            target = self
            action = #selector(didTapButton(sender:))
        }
    }
    
    @objc func didTapButton(sender: Any) {
        actionClosure?()
    }
    
    convenience init(barButtonSystemItem systemItem: UIBarButtonItem.SystemItem, actionClosure: @escaping () -> ()) {
        self.init(barButtonSystemItem: systemItem, target: nil, action: nil)
        self.actionClosure = actionClosure
    }
    
    convenience init(customView: UIView, actionClosure: @escaping () -> ()) {
        self.init(customView: customView)
        self.actionClosure = actionClosure
    }
    
    convenience init(image: UIImage?, style: UIBarButtonItem.Style, actionClosure: @escaping () -> ()) {
        self.init(image: image, style: style, target: nil, action: nil)
        self.actionClosure = actionClosure
    }
    
}


extension UIButton {
    private struct AssociatedObject {
        static var key = "action_closure_key"
    }
    
    var actionClosure: (() -> ())? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObject.key) as? () -> ()
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObject.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            addTarget(self, action: #selector(didTapButton(sender:)), for: .touchUpInside)
        }
    }
    
    @objc func didTapButton(sender: Any) {
        actionClosure?()
    }
    
}
