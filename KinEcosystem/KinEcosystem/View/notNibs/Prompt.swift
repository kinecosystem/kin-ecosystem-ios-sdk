//
//  Prompt.swift
//  KinEcosystem
//
//  Created by MNM on 08/07/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit
public typealias PromptCallback = () -> Void
public class Prompt: UIView {
    static var view:Prompt?
    static var balanceObserver:Any?
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var messageLabel:UILabel!
    private var content:UIView?
    static private var timer:Timer?
    public class func show(title:String,message:String,_ callback:PromptCallback? = nil,timeout:TimeInterval = 3)  {
        Prompt.hide(nil,animate:false) {
            if let window = UIApplication.shared.keyWindow {
                view = Prompt(frame:CGRect(x:10,y:UIApplication.shared.statusBarFrame.height + 5,width:window.frame.width - 20,height:70),title:title,message:message)
                UIApplication.shared.keyWindow?.addSubview(view!)
                view?.alpha = 0
                UIView.animate(withDuration: 0.5, animations: {
                    view?.alpha = 1
                })
                if timeout > 0 {
                    Prompt.timer = Timer.scheduledTimer(timeInterval:timeout, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: false)
                }
            }
        }
    }
    @objc class func handleTimer() {
        Prompt.hide()
    }
    public class func hide(_ prompt:Prompt? =  nil,animate:Bool = true, _ callback:PromptCallback? = nil) {
        if Prompt.timer?.isValid ?? false { Prompt.timer?.invalidate() }
        if prompt == Prompt.view || prompt == nil {
            print("animate",animate)
            UIView.animate(withDuration: animate ? 0.5 : 0.0 , animations: {
                view?.alpha = 0
            }) { finished in
                Prompt.view?.removeFromSuperview()
                Prompt.view = nil
                callback?()
            }
        }
    }
    fileprivate init(frame: CGRect,title:String?,message:String?) {
        super.init(frame:frame)
        content = Bundle(for: Prompt.self).loadNibNamed("Prompt", owner: self, options: nil)?.first as? UIView
        titleLabel.text = title
        messageLabel.text = message
        messageLabel.sizeToFit()
        addSubview(content!)
    }
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    override public func layoutSubviews() { content?.frame = bounds }
    @IBAction func handleTap(_ gr:UITapGestureRecognizer) {
        Prompt.hide(self,animate:true)
    }
}

