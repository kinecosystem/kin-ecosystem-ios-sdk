# kin-ecosystem-ios-sdk

## Intro
The ecosystem "5 minute SDK" supports rich user experience and seamless blockchain integration. <br/>
Once the ecosystem SDK is integrated within a digital service, users will be be able to interact with rich earn and spend marketplace experiences, and view their account balance and order history.<br/>
A stellar wallet and account will be created behind the scenes for the user. <br/>
The SDK also support purchase API to allow users to create spend transaction within the app - see the following section: [Using kin for native spend experience.](#using-kin-for-native-spend-experience)<br/>
Next version of the SDK and API will also suport native earn and P2P transactions.<br/>


## Installation
The fastest way to get started with the sdk is with cocoapods (>= 1.4.0).
```
pod 'KinEcosystem', '0.5.4'
```
> Notice for apps using swift 3.2: the pod installation will change your project's swift version target to 4.0</br>
> This is because the sdk uses swift 4.0, and cocoapods force the pod's swift version on the project. For now, you can manually change your project's swift version in the build setting. A better solution will be available soon.

## Usage

### Registration for Ecosystem backend service

Digital service application needs to initiate the Ecosystem sdk, which interacts with the ecosystem backend service. <br/>
<br/>
The Ecosystem backend is required for
1. Creating users accounts on the Stellar blockchain
1. Funds these account with initial XLM balance.
1. Serving KIN earn and spend offers for the SDK marketplace.
1. Mange and store user's earn and spend order history.

Therefore the ecosystem backend will block unauthorized requests.
Digital services will have to authorised client request using one of the following methods:
1. "whitelist" registration - used for quick first time integration or small internal testing.
    1. Whitelist registration requires a unique appID and apiKey.
    1. Please contact us to receive your unique appId and apiKey.
1. "JWT" registration - A secure register method for production ready application,
    1. "JWT" registration" use a Server side signed JWT token to authenticated client request.
    1. You can learn more [here](https://jwt.io)
    1. Please contact us to receive your JWT issuer identifier (iss key) and provide us with your public signature key and its corresponding 'keyid'

## Environment
Kin Ecosystem provides two working environments:
1. PRODUCTION - Production ecosystem servers and the main private blockchain network.
2. PLAYGROUND - A staging and testing environment running on test ecosystem servers and a private blockchain test network.<br>
You must specify an Environment on `Kin.shared.start(...)` as you will see in the following [section](app-id-and-key).

You should test the SDK with the PLAYGROUND enviorment using [PLAYGROUND test credentials](#playground-test-credentials).<br/>

The PLAYGROUND enviorment SLA of is not guaranteed.<br/>
Playground transaction are running on Kin PLAYGROUND blockchain.<br/>

The PRODUCTION enviorment is runnig on main production blockchain and containing real earn/spend offers, therfore required specifc credtials per digital services, please contact us for more details.<br/>

### JWT Registration specs
1. Playground will support `ES256` and `RS512` signature algorithm.
2. PRODUCTION will only support `ES256` signature algorithm.
3. The header will follow this template
    ```aidl
    {
        "alg": "RS512", // We will support ES256 signature algorithem
        "typ": "JWT",
        "kid": string" // identifier of the keypair that was used to sign the JWT. identifiers and public keys will be provided by signer authority. This enables using multiple private/public key pairs (a list of public keys and their ids need to be provided by signer authority to verifier in advanced)
    }
    ```

3. Here is the registration payload template
    ```aidl
    {
        // common/ standard fields
        iat: number;  // issued at - seconds from epoc
        iss: string; // issuer - please contact us to recive your issuer
        exp: number; // expiration
        sub: "register"

        // application fields
        user_id: string; // id of the user - or a deterministic unique id for the user (hash)
    }
    ```
#### Playground test credentials


    RS512_PRIVATE_KEY="MIICWwIBAAKBgQDdlatRjRjogo3WojgGHFHYLugdUWAY9iR3fy4arWNA1KoS8kVw33cJibXr8bvwUAUparCwlvdbH6dvEOfou0/gCFQsHUfQrSDv+MuSUMAe8jzKE4qW+jK+xQU9a03GUnKHkkle+Q0pX/g6jXZ7r1/xAK5Do2kQ+X5xK9cipRgEKwIDAQABAoGAD+onAtVye4ic7VR7V50DF9bOnwRwNXrARcDhq9LWNRrRGElESYYTQ6EbatXS3MCyjjX2eMhu/aF5YhXBwkppwxg+EOmXeh+MzL7Zh284OuPbkglAaGhV9bb6/5CpuGb1esyPbYW+Ty2PC0GSZfIXkXs76jXAu9TOBvD0ybc2YlkCQQDywg2R/7t3Q2OE2+yo382CLJdrlSLVROWKwb4tb2PjhY4XAwV8d1vy0RenxTB+K5Mu57uVSTHtrMK0GAtFr833AkEA6avx20OHo61Yela/4k5kQDtjEf1N0LfI+BcWZtxsS3jDM3i1Hp0KSu5rsCPb8acJo5RO26gGVrfAsDcIXKC+bQJAZZ2XIpsitLyPpuiMOvBbzPavd4gY6Z8KWrfYzJoI/Q9FuBo6rKwl4BFoToD7WIUS+hpkagwWiz+6zLoX1dbOZwJACmH5fSSjAkLRi54PKJ8TFUeOP15h9sQzydI8zJU+upvDEKZsZc/UhT/SySDOxQ4G/523Y0sz/OZtSWcol/UMgQJALesy++GdvoIDLfJX5GBQpuFgFenRiRDabxrE9MNUZ2aPFaFp+DyAe+b4nDwuJaW2LURbr8AEZga7oQj0uYxcYw\=\="
    APP_ID="test"
    API_KEY="A2XEJTdN8hGiuUvg9VSHZ"

### Onboarding

Once your app can provide a unique user id, call (depending on your onboarding method):

#### app id and key:
```swift
Kin.shared.start(userId: "myUserId", apiKey: "myAppKey", appId: "myAppId", environment: .playground)
```
#### jwt:
```swift
Kin.shared.start(userId: "myUserId", jwt: encodedJWT, environment: .playground)
```
>To view a full example of logging in with a [JWT](http://jwt.io) or an app key and id, check out the [sample app](https://github.com/kinecosystem/kin-ecosystem-ios-sample-app)

This will create the stack needed for running the ecosystem. All account creation and activation is handled for you by the sdk.</br>
Because blockchain onboarding might take a few seconds, It is strongly recommended to call this function as soon as you can provide a user id.

### Launching the marketplace experience
To launch the marketplace experience, with earn and spend opportunities, from a viewController, simply call:

```swift
Kin.shared.launchMarketplace(from: self)
```
### Getting your public address
Once kin is onboarded, you can view the stellar wallet address using:
```swift
Kin.shared.publicAddress
```
> note: this variable will return nil if called before kin is onboarded

### Getting your balance

Balance is represented by a `Balance` struct:
```swift
public struct Balance: Codable, Equatable {
    public var amount: Decimal
}
```

You can get your current balance using one of three ways:

#### Synchronously get the last known balance for the current account:

```swift
if let amount = Kin.shared.lastKnownBalance?.amount {
    print("your balance is \(amount) KIN")
} else {
  // Kin is not started or an account wasn't created yet.
}
```

#### Asynchronous call to the blockchain network:
```swift
Kin.shared.balance { balance, error in
    guard let amount = balance?.amount else {
        if let error = error {
            print("balance fetch error: \(error)")
        }
        return
    }
    print("your balance is \(amount) KIN")
}
```

#### Observing balance with a blockchain network observer:

```swift
var balanceObserverId: String? = nil
do {
    balanceObserverId = try Kin.shared.addBalanceObserver { balance in
        print("balance: \(balance.amount)")
    }
} catch {
    print("Error setting balance observer: \(error)")
}

// when you're done listening to balance changes, remove the observer:

if let observerId = balanceObserverId {
    Kin.shared.removeBalanceObserver(observerId)
}
```

### Using kin for native spend experience
A native spend is a mechanism allowing your users to buy virtual goods you define, using Kin on Kin Ecosystem API’s.</br>
A native spend offer requires you prepare an encoded jwt object, describing the offer:

1. We will support `ES256` signature algorithm later on, right now you can use `RS512`.
2. Header will follow this template
```aidl
    {
        "alg": "RS512", // We will support ES256 signature algorithem
        "typ": "JWT",
        "kid": string" // identifier of the keypair that was used to sign the JWT. identifiers and public keys will be provided by signer authority. This enables using multiple private/public key pairs (a list of public keys and their ids need to be provided by signer authority to verifier in advanced)
    }
```
3. SpendOffer payload template
```aidl
    {
        // common/ standard fields
        iat: number;  // issued at - seconds from epoc
        iss: string; // issuer - please contact us to recive your issuer
        exp: number; // expiration
        sub: "spend"

       // application fields
       offer: {
               id: string; // offer id is decided by you (internal)
               amount: number; // amount of kin for this offer - price
       }

       sender: {
              user_id: string; // optional: user_id who will perform the order
              title: string; // order title - appears in order history
              description: string; // order description - appears in order history
       }
    }
```

And to actually perform the purchase, call:
```swift
Kin.shared.purchase(offerJWT: encodedNativeOffer) { jwtConfirmation, error in
  if let confirm = jwtConfirmation {
    // success
  } else if let e = error {
    // error
  }
}
```
> A native spend example is also provided in the [sample app](https://github.com/kinecosystem/kin-ecosystem-ios-sample-app)

### Adding a Custom Spend Offer to the Kin Marketplace Offer Wall ###

The Kin Marketplace offer wall displays built-in offers, which are served by the Kin Ecosystem Server. Their purpose is to provide users with opportunities to earn initial Kin funding, which they can later spend on spend offers provided by hosting apps.

You can also choose to display a banner for your custom offer in the Kin Marketplace offer wall. This serves as additional "real estate" in which to let the user know about custom offers within your app. When the user clicks on your custom Spend offer in the Kin Marketplace, your app is notified, and then it continues to manage the offer activity in its own UX flow.

>**NOTE:** You will need to actively launch the Kin Marketplace offer wall so your user can see the offers you added to it.

*To add a custom Spend offer to the Kin Marketplace:*

1. Create a ```NativeSpendOffer``` struct as in the example below.

  ```swift
let offer = NativeOffer(id: "offer id", // OfferId must be a UUID
                        title: "offer title",
                        description: "offer description",
                        amount: 1000,
                        image: "an image URL string",
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

  >Note: Each new offer is added as the first offer in Spend Offers list the Marketplace displays.

  ```swift
  do {
      try Kin.shared.add(nativeOffer: offer)
  } catch {
      print("failed to add native offer, error: \(error)")
  }
  ```

### Removing a Custom Spend Offer from Kin Marketplace ###

*To remove a custom Spend offer from the Kin Marketplace:*

```swift
do {
    try Kin.shared.remove(nativeOfferId: offer.id)
} catch {
    print("Failed to remove offer, error: \(error)")
}
```

### Requesting Payment for a Custom Earn Offer ###

A custom Earn offer allows your users to earn Kin as a reward for performing tasks you want to incentivize, such as setting a profile picture or rating your app. (Custom offers are created by your app, as opposed to offers created by other platforms such as the Kin Ecosystem Server.)

>**NOTE:** For now, custom Earn offers must be displayed and managed by your app, and cannot be added to the Kin Marketplace (unlike custom Spend offers).

Once the user has completed the task associated with the Earn offer, you request Kin payment for the user.

*To request payment for a user who has completed an Earn offer:*

1.	Create a JWT that represents an Earn offer signed by you, using the header and payload templates below.

    **JWT header:**
    ```
    {
        "alg": "ES256", // Hash function
        "typ": "JWT",
        "kid": string" // identifier of the keypair that was used to sign the JWT. identifiers and public keys will be provided by signer authority. This enables using multiple private/public key pairs (a list of public keys and their ids need to be provided by signer authority to verifier in advanced)
    }
    ```

    **JWT payload:**
    ```
    {
        // common/ standard fields
        iat: number; // issued at - seconds from Epoch
        iss: string; // issuer
        exp: number; // expiration
        sub: "earn"

       // application fields
       offer: {
               id: string; // offer id is decided by you (internal)
               amount: number; // amount of kin for this offer - price
       }
       recipient: {
              user_id: string; // user_id who will perform the order
              title: string; // order title - appears in order history
              description: string; // order desc. (in order history)
       }
    }
    ```
2.	Call ```Kin.shared.requestPayment``` (see code example below). The Ecosystem Server credits the user account (assuming the app’s account has sufficient funds).

    >**NOTES:**
    >* The following snippet is taken from the SDK Sample App, in which the JWT is created and signed by the client side for presentation purposes only. Do not use this method in production! In production, the JWT must be signed by the server, with a secure private key.

    ```swift
    let handler: KinCallback = { jwtConfirmation, error in  
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        if let confirm = jwtConfirmation {
            alert.title = "Success"
            alert.message = "Earn complete. You can view the confirmation on jwt.io"
            alert.addAction(UIAlertAction(title: "View on jwt.io", style: .default, handler: { [weak alert] action in
                UIApplication.shared.openURL(URL(string:"https://jwt.io/#debugger-io?token=\(confirm)")!)
                alert?.dismiss(animated: true, completion: nil)
            }))
        } else if let e = error {
            alert.title = "Failure"
            alert.message = "Earn failed (\(e.localizedDescription))"
        }
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { [weak alert] action in
            alert?.dismiss(animated: true, completion: nil)
        }))
        self?.present(alert, animated: true, completion: nil)
    }

    Kin.shared.requestPayment(offerJWT: encodedJWT, completion: handler)
    ```
### Creating a Pay To User Offer ###

A pay to user offer allows user generated offers with which other users can interact.
(Offers are created by your app, as opposed to built-in offers displayed in the Kin Marketplace offer wall).
Your app displays the offer, requests user approval, and then requests payment using the Kin payToUser API.

### Requesting a Custom Pay To User Offer ###

*To request a Pay To User offer:*

1.	Create a JWT that represents a Pay To User offer signed by you, using the header and payload templates below.

**JWT header:**
```
{
    "alg": "ES256", // Hash function
    "typ": "JWT",
    "kid": string" // identifier of the keypair that was used to sign the JWT. identifiers and public keys will be provided by signer authority. This enables using multiple private/public key pairs (a list of public keys and their ids need to be provided by signer authority to verifier in advanced)
}
```

**JWT payload:**
```
{
    // common fields
    iat: number; // issued at - seconds from epoch
    iss: string; // issuer - request origin 'app-id' provided by Kin
    exp: number; // expiration
    sub: string; // subject - "pay_to_user"

    offer: {
        id: string; // offer id - id is decided by kik
        amount: number; // amount of kin for this offer - price
    },
    sender: {
        user_id: string; // optional: user_id who will perform the order
        title: string; // offer title - appears in order history
        description: string; // offer description - appears in order history
    },
    recipient: {
        user_id: string; // user_id who will receive the order
        title: string; // offer title - appears in order history
        description: string; // offer description - appears in order history
    }
}
```

2.	Call `Kin.shared.payToUser(…)`, while passing the JWT you built and a handler that will receive purchase confirmation.

> **NOTES:**
> * The following snippet is taken from the SDK Sample App, in which the JWT is created and signed by the iOS client side for presentation purposes only. Do not use this method in production! In production, the JWT must be signed by the server, with a secure private key.

```swift
let handler: KinCallback = { jwtConfirmation, error in
    DispatchQueue.main.async { [weak self] in
        self?.setActionRunning(false)
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        if let confirm = jwtConfirmation {
            alert.title = "Success"
            alert.message = "Payment complete. You can view the confirmation on jwt.io"
            alert.addAction(UIAlertAction(title: "View on jwt.io", style: .default, handler: { [weak alert] action in
                UIApplication.shared.openURL(URL(string:"https://jwt.io/#debugger-io?token=\(confirm)")!)
                alert?.dismiss(animated: true, completion: nil)
            }))
        } else if let e = error {
            alert.title = "Failure"
            alert.message = "Payment failed (\(e.localizedDescription))"
        }

        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { [weak alert] action in
            alert?.dismiss(animated: true, completion: nil)
        }))

        self?.present(alert, animated: true, completion: nil)
    }
}

_ = Kin.shared.payToUser(offerJWT: encoded, completion: handler)
```

3.	Complete the pay to user offer after you receive confirmation from the Kin Server that the funds were transferred successfully.

### Finding out if another user has a kin account ###

Before paying to a user, you might want to check if this user actually exists. to do that:

```swift
// from sample app:
Kin.shared.hasAccount(peer: otherUserId) { [weak self] response, error in
    if let response = response {
        guard response else {
            self?.presentAlert("User Not Found", body: "User \(otherUserId) could not be found. Make sure the receiving user has activated kin, and in on the same environment as this user")
            return
        }
        // Proceed with payment (transferKin is an internal function in the sample app)
        self?.transferKin(to: otherUserId, appId: id, pKey: jwtPKey)
    } else if let error = error {
        self?.presentAlert("An Error Occurred", body: "\(error.localizedDescription)")
    } else {
        self?.presentAlert("An Error Occurred", body: "unknown error")
    }
}
```

## License
The kin-ecosystem-ios-sdk library is licensed under [MIT license](LICENSE.md).
