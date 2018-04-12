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
pod 'KinEcosystem', '0.2.0'
```
> Notice for apps using swift 3.2: the pod installation will change your project's swift version target to 4.0</br>
> This is because the sdk uses swift 4.0, and cocoapods force the pod's swift version on the project. For now, you can manually change your project's swift version in the build setting. A better solution will be available soon.

## Usage

The ecosystem sdk needs at least three inputs to begin:
1. An app identifier. You obtain one by contacting Kin Foundation.
2. An app API key. You obtain one by contacting Kin Foundation.
3. A unique identifier for the current user.

> Note: There are a few more things you can configure when starting the sdk, such as running on test net or main net, using a jwt or a whitelist for user validation etc, but the above three are enough for a default run on the testnet.

Once your app can provide a unique user id, call:

```swift
Kin.shared.start(apiKey: [your api key], userId: [unique user id], appId: [app identifier])
```
This will create the stack needed for running the ecosystem. All account creation and activation is handled for you by the sdk.</br>
Because blockchain onboarding might take a few seconds, It is strongly recommended to call this function as soon as you can provide a user id.

To launch the marketplace experience, with earn and spend opportunities, from a viewController, simply call:

```swift
Kin.shared.launchMarketplace(from: self)
```

Some of the main to-do's still left:
- [ ] Network error handling
- [ ] Expose some more kin api's, like address, pay
- [ ] More control over Logger

## License
The kin-ecosystem-ios-sdk library is licensed under [MIT license](LICENSE.md).
