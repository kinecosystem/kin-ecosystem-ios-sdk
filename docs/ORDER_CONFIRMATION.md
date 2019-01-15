### Requesting an Order Confirmation ###

In the normal flow of a transaction, you will receive an order confirmation from the Kin Server through the purchase API's callback function. This indicates that the transaction was completed. But if you missed this notification for any reason, for example, because the user closed the app before it arrived, or the app closed due to some error, you can request confirmation for an order according to its ID.

*To request an order confirmation:*

Call `Kin.shared.orderConfirmation(…)`, while passing the offer's id and a callback handler.

```swift
Kin.shared.orderConfirmation(for: "NSOffer_01") { status, error in
    if let s = status, case let .completed(jwt) = s {
        print("order complete. jwt confirmation is: \(jwt)")
    } else {
        // handle errors
    }
}
```
