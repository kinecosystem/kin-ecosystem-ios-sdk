# Kin Ecosystem iOS SDK #

## What is the Kin Ecosystem SDK? ##

The Kin Ecosystem SDK allows you to quickly and easily integrate with the Kin platform. This enables you to provide your users with new opportunities to earn and spend the Kin digital currency from inside your app or from the Kin Marketplace offer wall. For each user, the SDK will create wallet and an account on Kin blockchain. By calling the appropriate SDK functions, your application can performs earn and spend transactions. Your users can also view their account balance and their transaction history.

## Installation
The fastest way to get started with the sdk is with cocoapods (>= 1.4.0).
```
pod 'KinEcosystem', '0.6.3'
```
> Notice for apps using swift 3.2: the pod installation will change your project's swift version target to 4.0</br>
> This is because the sdk uses swift 4.0, and cocoapods force the pod's swift version on the project. For now, you can manually change your project's swift version in the build setting. A better solution will be available soon.

## Usage

> **Important note:** Apps using the sdk must include a NSPhotoLibraryUsageDescription key entry in the info.plist file. This is becuase the sdk may ask to use the photos library when restoring a backed up wallet. For example, you can use something like:</br>
"_Photo library access is required for backup and restore of your kin wallet_"
</br></br>
If your app already includes such an entry, you do not need to change anything.


## Beta and Production Environments ##

The Kin Ecosystem provides two working environments:

- **Beta** – a staging and testing environment using test servers and a blockchain test network.
- **Production** – uses production servers and the main blockchain network.

Use the Beta environment to develop, integrate and test your app. Transition to the Production environment when you’re ready to go live with your Kin-integrated app.

>**NOTES:**
>* When working with the Beta environment, you can only register up to 1000 users. An attempt to register additional users will result in an error.

## Initialize The SDK ##
Kin Ecosystem SDK must be initialized before any interaction with the SDK, in order to do that you should call ```Kin.shared.start(environment: Environment)``` first.


   >**NOTE** `start` method does not perform any network calls and it's a synchronous method. If anything goes wrong during start, an error will be thrown.

## Obtaining Authentication Credentials ##

To access the Kin Ecosystem, you’ll need to obtain authentication credentials, which you then use to register your users.

* **JWT authentication** – a secure authentication method to be used in production. This method uses a JSON Web Token (JWT) signed by the Kin Server to authenticate the client request. You provide the Kin team with one or more public signature keys and its corresponding keyID, and you receive a JWT issuer identifier (ISS key). (See [https://jwt.io](https://jwt.io) to learn more about JWT tokens.)

You supply your credentials when calling the SDK’s ```Kin.login(…)``` function for a specific user. See [Creating a User’s Kin Account](docs/CREATE_ACCOUNT.md) to learn more about login and logout.

## Generating the JWT Token ##

A JWT token is a string that is composed of 3 parts:

* **Header** – a JSON structure encoded in Base64Url
* **Payload** – a JSON structure encoded in Base64Url
* **Signature** – constructed with this formula:

    ```ES256(base64UrlEncode(header) + "." + base64UrlEncode(payload), secret)```

    -- where the secret value is the private key of your agreed-on public/private key pair.

The 3 parts are then concatenated, with the ‘.’ character between each 2 consecutive parts, as follows:

```<header> + “.” + <payload> + “.” + <signature>```

See https://jwt.io to learn more about how to build a JWT token, and to find libraries that you can use to do this.

This is the header structure:

```
{
    "alg": "ES256",
    "typ": "JWT",
    "kid": string" // ID of the keypair that was used to sign the JWT.
    // IDs and public keys will be provided by the signing authority.
    // This enables using multiple private/public key pairs.
    // (The signing authority must provide the verifier with a list of public
    // keys and their IDs in advance.)
}
```

This is the payload structure:

```
{
    // standard fields
    iat: number;  // the time this token was issued, in seconds from Epoch
    iss: string;  // issuer (Kin will provide this value)
    exp: number;  // the time until this token expires, in seconds from Epoch
    sub: "register"

    // application fields
    user_id: string; // A unique ID of the end user (must only be unique among your app’s users; not globally unique)
    device_id: string; // A unique ID of the user's device
}
```

## Primary APIs ##

The following sections show how to implement some primary APIs using the Kin Ecosystem SDK.

* [Creating a User’s Kin Account](docs/CREATE_ACCOUNT.md)
  
* [Getting an Account’s Balance](docs/BALANCE.md)

* [Requesting Payment for a Custom Earn Offer](docs/NATIVE_EARN.md)

* [Creating a Custom Spend Offer](docs/NATIVE_SPEND.md)

* [Creating a Pay To User Offer](docs/PEER_TO_PEER.md)

* [Displaying the Kin Marketplace](docs/DISPLAY_EXPERIENCE.md)

* [Adding Native Offers to the Marketplace Offer Wall](docs/ADD_NATIVE_OFFER_TO_MARKETPLACE.md)

* [Requesting an Order Confirmation](docs/ORDER_CONFIRMATION.md)

* [Misc](docs/MISC.md)

## License ##

The ```kin-ecosystem-ios-sdk``` library is licensed under the MIT license.
