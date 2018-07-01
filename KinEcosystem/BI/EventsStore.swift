//
//  EventsStore.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 27/06/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

public class EventsStore {
    public static let shared = EventsStore()
    private init() {}
    public var userProxy: UserProxy?
    public var clientProxy: ClientProxy?
    public var commonProxy: CommonProxy?
}
