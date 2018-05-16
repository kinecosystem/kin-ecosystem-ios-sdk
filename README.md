# kin-ecosystem-ios-sdk

## Disclaimer
The iOS Kin Ecosystem sdk is still work in progress, meaning, you are welcome to try it,<br/>
but don't integrate it into your production app just yet.
The backend service supporting the ecosystem sdk is in test mode and SLA is not guarantee.<br/>
All blockchain transactions are currently running on Stellar test net and not on main net.<br/>


## Intro
The ecosystem "5 minute SDK" supports rich user experience and seamless blockchain integration. <br/>
Once the ecosystem SDK is integrated within a digital service, users will be be able to interact with rich earn and spend marketplace experiences, and view their account balance and order history.<br/>
A stellar wallet and account will be created behind the scenes for the user. <br/>

## Installation
The fastest way to get started with the sdk is with cocoapods (>= 1.4.0).
```
pod 'KinEcosystem', '0.3.0'
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

### JWT Registration specs
1. We will support `ES256` signature algorithm later on, right now you should use `RS512`.
2. The header will follow this template
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



### Onboarding
Once your app can provide a unique user id, call (depending on your onboarding method):

#### app id and key:
```swift
Kin.shared.start(apiKey: "myAppKey"", userId: "myUserId", appId: "myAppId")
```
#### jwt:
```swift
Kin.shared.start(apiKey: "", userId: "myUserId", appId: "myAppId", jwt: encodedJWT)
```
>To view a full example of logging in with a [JWT](http://jwt.io) or an app key and id, check out the [sample app](https://github.com/kinecosystem/kin-ecosystem-ios-sample-app)

This will create the stack needed for running the ecosystem. All account creation and activation is handled for you by the sdk.</br>
Because blockchain onboarding might take a few seconds, It is strongly recommended to call this function as soon as you can provide a user id.

Also provided is a completion block you can pass to the start method:
```swift
Kin.shared.start(apiKey: "myAppKey", userId: "myUserId", appId: "myAppId") { error in
    if let error = error {
      print("start failed")
      return
    }
    // do stuff with kin
}
```
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
You can get your current balance using one of two ways:

#### Single asynchronous call:
```swift
Kin.shared.balance { balance in
    print("you have \(balance) kin")
}
```
> note: this call will simply return 0 if balance could not be read from blockchain

#### Observing balance (recommended):

When observing balance this way, you get a stateful balance object:
```swift
public enum StatfulBalance {
    case pendind(Decimal)
    case errored(Decimal)
    case verified(Decimal)
}
```
##### Balance states
###### pending
 The associated amount is expected to be the verified amount. The balance observer moves to a pending state before a transaction (in or out) is expected by the sdk, or before any actual blockchain balance was verified.
###### errored
The blockchain balance could not be read at this time. You may get this value if an account isn't yet created or funded, or an actual error occurred while trying to access the blockchain.
###### verified
The associated value was just read from the blockchain.
##### Usage
```swift
import KinUtil

// a link bag is an optional kin utility you should use for observing
let bag = LinkBag()
...
func observeBalance() {
    if let balance = Kin.shared.balanceObserver {
        balance.on(queue: .main, next: { balanceState in
            print("balance: \(balanceState)")
        }).add(to: self.bag)
    }
}
```
> note: `balanceObserver` will return nil if called before kin is onboarded

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
                title: string; // offer title - appears in order history
                description: string; // offer description - appears in order history
                amount: number; // amount of kin for this offer - price
                wallet_address: string; // address the client should send kin to to acquire this offer
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
