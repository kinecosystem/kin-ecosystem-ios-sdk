//
//  String+Localization.swift
//  KinAppreciationModuleOptionsMenu
//
//  Created by Corey Werner on 19/06/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

extension String {
    func localized(_ args: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, tableName: nil, bundle: .appreciation, value: "", comment: ""), arguments: args)
    }
}
