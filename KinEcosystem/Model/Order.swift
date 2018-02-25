//
//  Order.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 20/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreData

class OrdersList: EntityPresentor {
    typealias entitiy = Order
    var orders: [Order]
    var entities: [Order] {
        return orders
    }
}

class Order: NSManagedObject, NetworkSyncable {
    
    @NSManaged public var completion_date: NSDate
    @NSManaged public var offer_type: String
    @NSManaged public var order_id: String
    @NSManaged public var status: String
    @NSManaged public var title: String
    @NSManaged public var description_: String
    @NSManaged public var call_to_action: String?
    @NSManaged public var amount: Int32
    @NSManaged public var blockchain_data: OrderBlockchainData?
    @NSManaged public var result: OrderResult?
    
    var offerType: OfferType {
        get { return OfferType(rawValue: offer_type)! }
        set { offer_type = newValue.rawValue }
    }
    
    enum OrderKeys: String, CodingKey {
        case completion_date
        case offer_type
        case order_id
        case status
        case title
        case description
        case call_to_action
        case amount
        case blockchain_data
        case result
    }
    
    func update(_ from: Order) {
        completion_date = from.completion_date
        offer_type = from.offer_type
        order_id = from.order_id
        status = from.status
        title = from.title
        description_ = from.description_
        call_to_action = from.call_to_action
        amount = from.amount
        blockchain_data = from.blockchain_data
        result = from.result
    }
    
    var syncId: String {
        return order_id
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.context] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Order", in: managedObjectContext) else {
                fatalError()
        }
        
        self.init(entity: entity, insertInto: nil)
        let values = try decoder.container(keyedBy: OrderKeys.self)
        
        if  let dateString = try? values.decode(String.self, forKey: .completion_date),
            let date = Iso8601DateFormatter.date(from: dateString) {
            completion_date = date as NSDate
        }
        offer_type = try values.decode(String.self, forKey: .offer_type)
        order_id = try values.decode(String.self, forKey: .order_id)
        status = try values.decode(String.self, forKey: .status)
        title = try values.decode(String.self, forKey: .title)
        description_ = try values.decode(String.self, forKey: .description)
        call_to_action = try values.decodeIfPresent(String.self, forKey: .call_to_action)
        amount = try values.decode(Int32.self, forKey: .amount)
        blockchain_data = try values.decodeIfPresent(OrderBlockchainData.self, forKey: .blockchain_data)
        result = try values.decodeIfPresent(OrderResult.self, forKey: .result)
        
    }
}
