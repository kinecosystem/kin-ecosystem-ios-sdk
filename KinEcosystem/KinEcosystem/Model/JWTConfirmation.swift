//
//  JWTConfirmation.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 09/05/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreData

class JWTConfirmation : OrderResult, Decodable {
    
    @NSManaged public var jwt: String
    
    enum JWTConfirmationKeys: String, CodingKey {
        case jwt
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.context] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "JWTConfirmation", in: managedObjectContext) else {
                fatalError()
        }
        
        // initializing subclasses of OrderResult is more coutious than other classes.
        // Mind and keep the order of checks here
        let values = try decoder.container(keyedBy: JWTConfirmationKeys.self)
        if let jwtString = try? values.decode(String.self, forKey: .jwt) {
            self.init(entity: entity, insertInto: managedObjectContext)
            jwt = jwtString
            type = OrderResultType.jwt.rawValue
        } else {
            throw EcosystemDataError.decodeError
        }
        
        
        
    }
    
}
