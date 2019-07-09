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
    @IBOutlet var label:UILabel!
    lazy private var content:Prompt? = Bundle(for: Prompt.self).loadNibNamed("Prompt", owner: self, options: nil)?.first as? Prompt
    public class func show(title:String,message:String,_ callback:PromptCallback? = nil)  {
        Prompt.hide {
            if let window = UIApplication.shared.keyWindow {
                view =  Prompt(frame:CGRect(x:5,y:UIApplication.shared.statusBarFrame.height + 5,width:window.frame.width - 10,height:80))
                UIApplication.shared.keyWindow?.addSubview(view!)
            }
        }
    }
    public class func hide(animate:Bool = true, _ callback:PromptCallback? = nil) {
        Prompt.view?.removeFromSuperview()
        callback?()
    }
    public override init(frame: CGRect) {
        super.init(frame:frame)
        if let content = content {
             addSubview(content)
        }
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

