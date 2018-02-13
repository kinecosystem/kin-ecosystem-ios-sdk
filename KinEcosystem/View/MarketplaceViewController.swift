//
//  MarketplaceViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 13/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class MarketplaceViewController: UIViewController {

    weak var data: EcosystemData?
    weak var net: EcosystemNet?
    @IBOutlet weak var topViewContainer: UIView!
    @IBOutlet weak var bottomViewContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
