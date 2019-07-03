import Foundation

/// common user properties
struct User: Codable {
    let balance: Double
    let digitalServiceID, digitalServiceUserID: String
    let earnCount: Int
    let entryPointParam: String
    let spendCount: Int
    let totalKinEarned, totalKinSpent: Double
    let transactionCount: Int

    enum CodingKeys: String, CodingKey {
        case balance
        case digitalServiceID = "digital_service_id"
        case digitalServiceUserID = "digital_service_user_id"
        case earnCount = "earn_count"
        case entryPointParam = "entry_point_param"
        case spendCount = "spend_count"
        case totalKinEarned = "total_kin_earned"
        case totalKinSpent = "total_kin_spent"
        case transactionCount = "transaction_count"
    }
}

public struct UserProxy {
    var balance: () -> (Double)
    var digitalServiceID: () -> (String)
    var digitalServiceUserID: () -> (String)
    var earnCount: () -> (Int)
    var entryPointParam: () -> (String)
    var spendCount: () -> (Int)
    var totalKinEarned: () -> (Double)
    var totalKinSpent: () -> (Double)
    var transactionCount: () -> (Int)
    var snapshot: User {
        return User(
            balance: balance(),
            digitalServiceID: digitalServiceID(),
            digitalServiceUserID: digitalServiceUserID(),
            earnCount: earnCount(),
            entryPointParam: entryPointParam(),
            spendCount: spendCount(),
            totalKinEarned: totalKinEarned(),
            totalKinSpent: totalKinSpent(),
            transactionCount: transactionCount())
    }
}
