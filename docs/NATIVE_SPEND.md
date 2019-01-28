### Using kin for a native spend experience
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
              device_id: string; // A unique ID of the purchasing user device
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
