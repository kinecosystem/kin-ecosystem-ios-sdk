//
//  Prompt.swift
//  KinEcosystem
//
//  Created by Alon Genosar on 08/07/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit
public enum PromptCallbackAction    { case tapBody,tapCloseButton,hide }
public enum PromptConfig            { case hasCloseButton,closeOnTap }
typealias PromptCallback = (PromptCallbackAction) -> Void
class Prompt: UIView {
    static var current:Prompt?
    static var balanceObserver:Any?
    static private var timer:Timer?
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var messageLabel:UILabel!
    private var content:UIView?
    private var callback:PromptCallback?
    class func show(title:String,message:String,timeout:TimeInterval = 3, config:[PromptConfig]? = nil, _ callback:PromptCallback? = nil)  {
        Prompt.hide(nil,animate:false) { action in
            if let window = UIApplication.shared.keyWindow {
                current = Prompt(frame:CGRect(x:10,y:UIApplication.shared.statusBarFrame.height + 5,width:window.frame.width - 20,height:70),title:title,message:message)
                current?.callback = callback
                UIApplication.shared.keyWindow?.addSubview(current!)
                current?.alpha = 0
                UIView.animate(withDuration: 0.5, animations: {
                    current?.alpha = 1
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
    class func hide(_ prompt:Prompt? =  nil,animate:Bool = true, _ callback:PromptCallback? = nil) {
        if Prompt.timer?.isValid ?? false { Prompt.timer?.invalidate() }
        if prompt == Prompt.current || prompt == nil {
            print("animate",animate)
            UIView.animate(withDuration: animate ? 0.5 : 0.0 , animations: {
                current?.alpha = 0
            }) { finished in
                Prompt.current?.removeFromSuperview()
                Prompt.current = nil
                callback?(.hide)
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
        callback?(.tapBody)
    }
    @IBAction func handleCloseButtonTap(_ gr:UIButton) {
        Prompt.hide(self,animate:true)
        callback?(.tapCloseButton)
    }
}

