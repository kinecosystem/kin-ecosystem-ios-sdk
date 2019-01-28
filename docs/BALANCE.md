### Getting an Account’s Balance ###

A user’s balance is the number of Kin units in his or her account (can also contain a fraction). You may want to retrieve the balance in response to a user request or to check whether a user has enough funding to perform a Spend request. When you request a user’s balance, you receive a `Balance` object in response, which contains the amount as a `Decimal` object.

There are 3 ways you can retrieve the user’s balance:

* Get the cached balance (the last balance that was received on the client side). The cached balance is updated upon SDK initialization and for every transaction. Usually, this will be the same balance as the one stored in the Kin blockchain. But in some situations it might not be up to date, for instance due to network connection issues.
* Get the balance from the Kin Server (the balance stored in the Kin blockchain). This is the definitive balance value. This is an asynchronous call that requires you to implement callback functions.
* Create an `Observer` object that receives notifications when the user’s balance changes.

*To get the cached balance, use:*

`Kin.shared.lastKnownBalance`.
> This value may be nil if no known balance is present (for example, no account is associated yet)

*To get the balance from the Kin Server (from the blockchain), use:*

```swift
    Kin.shared.balance() { balance, error in
        if let b = balance {
            print("balance is \(b.amount)")
        } else if let e = error {
            print("error getting balance: \(e.localizedDescription)")
        }
    }
```

*To listen continuously for balance updates:*


```swift
var balanceObserverId: String? = nil
do {
    balanceObserverId = try Kin.shared.addBalanceObserver { balance in
        print("balance: \(balance.amount)")
    }
} catch {
    print("Error setting balance observer: \(error)")
}
```

When you're done listening to balance changes, remove the observer:

```swift
if let observerId = balanceObserverId {
    Kin.shared.removeBalanceObserver(observerId)
}
```
