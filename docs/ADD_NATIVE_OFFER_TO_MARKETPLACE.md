### Adding a Custom Offer to the Kin Marketplace Offer Wall ###

The Kin Marketplace offer wall displays built-in offers, which are served by the Kin Ecosystem Server. Their purpose is to provide users with opportunities to earn initial Kin funding, which they can later spend on spend offers provided by hosting apps.

You can also choose to display a banner for your custom offer in the Kin Marketplace offer wall. This serves as additional "real estate" in which to let the user know about custom offers within your app. When the user clicks on your custom offer in the Kin Marketplace, your app is notified, and then your app continues to manage the offer activity in its own UX flow.

>**NOTE:** You will need to actively launch the Kin Marketplace offer wall so your user can see the offers you added to it.

*To add a custom offer to the Kin Marketplace:*

1. Create a ```NativeSpendOffer``` struct as in the example below.

  ```swift
let offer = NativeOffer(id: "offer id", // OfferId must be a UUID
                        title: "offer title",
                        description: "offer description",
                        amount: 1000,
                        image: "an image URL string",
                        offerType: .spend, // or .earn
                        isModal: true)
```
> Note: setting a native offer's `isModal` property to true means that when a user taps on the native offer, the marketplace will first close (dismiss) before invoking the native offer's handler, if set. The default value is false.

2.	Set the  `nativeOfferHandler` closure on Kin.shared to receive a callback when the native offer has been tapped.</br>
The callback is of the form `public var nativeOfferHandler: ((NativeOffer) -> ())?`

  ```swift
// example from the sample app:
Kin.shared.nativeOfferHandler = { offer in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Native Offer", message: "You tapped a native offer and the handler was invoked.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { [weak alert] action in
                    alert?.dismiss(animated: true, completion: nil)
                }))

                let presentor = self.presentedViewController ?? self
                presentor.present(alert, animated: true, completion: nil)
            }
        }
```

3.	Add the native offer you created in the following way:

  >Note: Each new offer is added as the first offer in the relevant offers list the Marketplace displays.

  ```swift
  do {
        try Kin.shared.add(nativeOffer: offer)
  } catch {
        print("failed to add native offer, error: \(error)")
  }
  ```

### Removing a Custom offer from Kin Marketplace ###

*To remove a custom offer from the Kin Marketplace:*

```swift
do {
    try Kin.shared.remove(nativeOfferId: offer.id)
} catch {
    print("Failed to remove offer, error: \(error)")
}
```
