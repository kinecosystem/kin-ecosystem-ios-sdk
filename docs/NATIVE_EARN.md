### Requesting Payment for a Custom Earn Offer ###

A custom Earn offer allows your users to earn Kin as a reward for performing tasks you want to incentivize, such as setting a profile picture or rating your app. (Custom offers are created by your app, as opposed to offers created by other platforms such as the Kin Ecosystem Server.)

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
              device_id: string; // A unique ID of the recipient user device
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
