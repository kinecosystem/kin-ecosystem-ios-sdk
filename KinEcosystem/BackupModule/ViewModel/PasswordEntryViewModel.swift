//
//  PasswordEntryViewModel.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 16/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
struct PasswordEntryViewModel {
    
    let passwordTitle = "kinecosystem_create_password".localized().attributed(20.0, weight: .light, color: UIColor.kinPrimaryBlue)
    let passwordInfo = "kinecosystem_password_instructions".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
    let confirmInfo = "kinecosystem_password_confirmation".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
    var ticked = false
    var password1 = ""
    var password2 = ""
    var passwordsMatch: Bool {
        get {
            return password1 == password2
        }
    }
    
}
