//
//  Prompt.swift
//  KinEcosystem
//
//  Created by Alon Genosar on 08/07/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit
public enum PromptCallbackAction    { case tapBody,tapCloseButton,hide }
typealias PromptCallback = (PromptCallbackAction) -> Void
class Prompt: UIView {
    static var current:UIView?
    static private var timer:Timer?
    private static var callback:PromptCallback?
    class func show(view:UIView, timeout:TimeInterval = 3, _ callback:PromptCallback? = nil)  {
        Prompt.hide(nil,animate:false) { action in
            current = view
            if let window = UIApplication.shared.keyWindow {
                let targetY = view.y
                view.alpha = 0
                view.y = -view.height / 2
                print(view)
                window.addSubview(view)
                UIView.animate(withDuration: 0.4, animations: {
                    view.alpha = 1
                    view.y = targetY
                })
                if timeout > 0 {
                    Prompt.timer = Timer.scheduledTimer(timeInterval:timeout, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: false)
                }
            }
        }
    }
    @objc class func handleTimer() { Prompt.hide() }
    class func hide(_ view:UIView? =  nil,animate:Bool = true, _ callback:PromptCallback? = nil) {
        if Prompt.timer?.isValid ?? false { Prompt.timer?.invalidate() }
        if view == Prompt.current || view == nil {
            UIView.animate(withDuration: animate ? 0.3 : 0.0 , animations: {
                current?.alpha = 0
            }) { finished in
                Prompt.current?.removeFromSuperview()
                Prompt.current = nil
                callback?(.hide)
            }
        }
    }
}
