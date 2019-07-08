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
    typealias entity = Order
    var orders: [entity]?
    var entities: [entity]? {
        return orders
    }
}

enum OrderStatus: String {
    case pending
    case completed
    case delayed
    case failed
}

class Order: NSManagedObject, NetworkSyncable {
    
    @NSManaged public var completion_date: NSDate
    @NSManaged public var offer_type: String
    @NSManaged public var id: String
    @NSManaged public var offer_id: String
    @NSManaged public var status: String
    @NSManaged public var title: String
    @NSManaged public var description_: String
    @NSManaged public var call_to_action: String?
    @NSManaged public var content: String?
    @NSManaged public var amount: Int32
    @NSManaged public var blockchain_data: BlockchainData?
    @NSManaged public var result: OrderResult?
    @NSManaged public var error: OrderError?
    // not a decoded property
    @NSManaged public var position: Int32
    
    var offerType: OfferType {
        get { return OfferType(rawValue: offer_type)! }
        set { offer_type = newValue.rawValue }
    }
    
    var orderStatus: OrderStatus {
        get { return OrderStatus(rawValue: status)! }
        set { status = newValue.rawValue }
    }
    
    let allowedStatusChanges: [OrderStatus:[OrderStatus]] = [.pending:[.completed,
                                                                       .failed,
                                                                       .delayed],
                                                             .delayed:[.completed,
                                                                       .failed]]
    
    enum OrderKeys: String, CodingKey {
        case completion_date
        case offer_type
        case id
        case offer_id
        case status
        case title
        case description
        case call_to_action
        case content
        case amount
        case blockchain_data
        case result
        case error
    }
    
    func update(_ from: Order, in context: NSManagedObjectContext) {
        guard from != self else { return }
        completion_date = from.completion_date
        offer_type = from.offer_type
        id = from.id
        offer_id = from.offer_id
        if allowedStatusChanges.contains(where: { key, value -> Bool in
            return (key == orderStatus && value.contains(from.orderStatus))
        }) {
            status = from.status
        }
        title = from.title
        description_ = from.description_
        call_to_action = from.call_to_action
        amount = from.amount
        content = from.content
        position = from.position
        // don't leave dangling relationships
        if let data = blockchain_data, data != from.blockchain_data {
            context.delete(data)
        }
        blockchain_data = from.blockchain_data
        if let res = result, res != from.result {
            context.delete(res)
        }
        result = from.result
        if let err = error, err != from.error {
            context.delete(err)
        }
        error = from.error
    }
    
    var syncId: String {
        return id
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.context] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Order", in: managedObjectContext) else {
                fatalError()
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        let values = try decoder.container(keyedBy: OrderKeys.self)
        
        if  let dateString = try? values.decode(String.self, forKey: .completion_date),
            let date = Iso8601DateFormatter.date(from: dateString) {
            completion_date = date as NSDate
        }
        offer_type = try values.decode(String.self, forKey: .offer_type)
        id = try values.decode(String.self, forKey: .id)
        offer_id = try values.decode(String.self, forKey: .offer_id)
        status = try values.decode(String.self, forKey: .status)
        title = try values.decode(String.self, forKey: .title)
        description_ = try values.decode(String.self, forKey: .description)
        call_to_action = try values.decodeIfPresent(String.self, forKey: .call_to_action)
        content = try values.decodeIfPresent(String.self, forKey: .content)
        amount = try values.decode(Int32.self, forKey: .amount)
        blockchain_data = try values.decodeIfPresent(BlockchainData.self, forKey: .blockchain_data)
        error = try values.decodeIfPresent(OrderError.self, forKey: .error)
        
        // initializing subclasses of OrderResult is more coutious than other classes.
        // Mind and keep the order of checks here
        if let coupon = try? values.decodeIfPresent(CouponCode.self, forKey: .result) {
            result = coupon
        } else if let jwt = try? values.decodeIfPresent(JWTConfirmation.self, forKey: .result) {
            result = jwt
        }
        
    }
    
    func willDelete() -> Bool {
        return true
    }
}
