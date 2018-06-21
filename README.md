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
pod 'KinEcosystem', '0.4.3'
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

## License
The kin-ecosystem-ios-sdk library is licensed under [MIT license](LICENSE.md).
