### Launching the ecosystem experience
The ecosystem experience can be launched at one of two entry points:
1. Marketplace - where users can view earn and spend offers
2. Orders history - where users can view their spend and earn history
> The default target for opening the ecosystem is the marketplace. Here's an example of launching the experience right at the history page:

```swift
try? Kin.shared.launchEcosystem(from: self, at: .history)
```
