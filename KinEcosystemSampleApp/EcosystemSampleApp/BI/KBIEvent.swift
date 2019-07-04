//
//  KBIEvent.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/06/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

protocol KBIEvent: Codable {
    var common: Common { get }
    var eventName: String { get }
}
