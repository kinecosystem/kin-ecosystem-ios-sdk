//
//  String+localized.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 08/10/2018.
//

import Foundation
extension String {
    func localized(_ args: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, tableName: nil, bundle: Bundle.ecosystem, value: "", comment: ""), arguments: args)
    }
}
