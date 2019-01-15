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
        id: string; // offer id - id is decided by digital service
        amount: number; // amount of kin for this offer - price
    },
    sender: {
        user_id: string; // user_id who will perform the order
        device_id: string; // A unique ID of the sender's device
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
