### Creating a User’s Kin Account ###

If your app presents Kin Spend and Earn offers to your users, then each user needs a Kin wallet and account in order to take advantage of those offers.

>**NOTE:** Kin Ecosystem SDK must be initialized before any interaction with the SDK, in order to do that you should call `Kin.start(…)` first.


#### Login
*To create or access a user’s Kin account:*

Call `Kin.login(…)`, passing JWT credentials and an optional `KinLoginCallback` to get a response when the user is logged in and has a wallet ready for use.</br>
You can immidietly call other functions after calling login. Any login or wallet creation/retrieval operations will be performed first and your calls will queue until these are done. The 'KinLoginCallback' is an optional parameter allowing you to know when login is complete, in case you need it.

**JWT mode:**

(See [Building the JWT Token](../README.md#generating-the-jwt-token) to learn how to build the JWT token.)

```swift
    try Kin.shared.login(jwt: encodedJWT) { error in
        guard let e = error else {
            print("login success")
            return
        }
        print("login failed. Error: \(error.localizedDescription)")
    }
```

#### Logout
*To release access from a user’s Kin account or switch account:*

Call `Kin.shared.logout()`, this is a synchronous call, meaning you can call `Kin.shared.login(…)` immediately after that (for switching between users).
