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

### User's Order History Stats ###

This API provides user's stats which include information such number of Earn/Spend orders completed by the user or last earn/spend dates.
UserStats information could be used for re-engaging users, provide specific experience for users who never earn before etc.

```swift
Kin.shared.userStats { [weak self] stats, error in
    if let result = stats {
        self?.presentAlert("User Stats", body: result.description)
    } else if let err = error {
        self?.presentAlert("Error", body: err.localizedDescription)
    } else {
        self?.presentAlert("Error", body: "Unknown Error")
    }
}
```
