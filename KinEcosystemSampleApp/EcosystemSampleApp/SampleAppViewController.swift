//
//  ViewController.swift
//  EcosystemSampleApp
//
//  Created by Elazar Yifrach on 14/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinEcosystem
import JWT
enum UIState { case disabled,onlyLogin,enabled }
class SampleAppViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var currentUserLabel: UILabel!
    @IBOutlet weak var loginOutButton: UIButton!
    @IBOutlet weak var externalIndicator: UIActivityIndicatorView!
    @IBOutlet weak var buyStickerButton: UIButton!
    @IBOutlet weak var getKinButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var cover: UIView!
    @IBOutlet var coverTopConstraint: NSLayoutConstraint!
    private var uiState:UIState = .disabled {
            didSet {
                switch uiState {
                case .disabled:
                cover.isHidden = false
                coverTopConstraint.isActive = false
                externalIndicator.startAnimating()
                break
                    
                case .enabled:
                cover.isHidden = true
                externalIndicator.stopAnimating()
                break

                case .onlyLogin:
                cover.isHidden = false
                print(coverTopConstraint)
                coverTopConstraint.isActive = true
                externalIndicator.stopAnimating()
                break
            }
        }
    }
    var balance: Decimal = 0

    let environment: Environment = .test
    let kid = "rs512_0"
    var appId: String? {
        return ApplicationKeys.AppId.isEmpty == false ? ApplicationKeys.AppId : configValue(for: "appId", of: String.self)
    }
    var privateKey: String? {
        return ApplicationKeys.AppPrivateKey.isEmpty == false ? ApplicationKeys.AppPrivateKey : configValue(for: "RS512_PRIVATE_KEY", of: String.self)
    }
    var lastUser: String? {
        get {
            if let user = UserDefaults.standard.string(forKey: "SALastUser") {
                return user
            }
            return nil
        }
    }
    
    lazy var deviceId: String = {
        var identifier: String
        if let vendorIdentifier = UIDevice.current.identifierForVendor?.uuidString {
            identifier = vendorIdentifier
        } else if let uuid = UserDefaults.standard.string(forKey: "sampleAppDeviceIdentifier") {
            identifier = uuid
        } else {
            let uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: "sampleAppDeviceIdentifier")
            identifier = uuid
        }
        return identifier
    }()
    
    func configValue<T>(for key: String, of type: T.Type) -> T? {
        if  let path = Bundle.main.path(forResource: "defaultConfig", ofType: "plist"),
            let value = NSDictionary(contentsOfFile: path)?[key] as? T {
            return value
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        titleLabel.text = "\(version) (\(build))"
        _ = Kin.shared.addBalanceObserver { balance in
            DispatchQueue.main.async {
                self.balance = balance.amount
                self.balanceLabel.text = "\(balance.amount) K"
            }
        }
        startKin()
       // print( Kin.shared.isLoggedIn )
        
    }
    override func viewWillAppear(_ animated: Bool) {
//        if uiState != .disabled {
//            uiState = Kin.shared.isLoggedIn ? .enabled : .onlyLogin
//        }
    }
    func alertConfigIssue() {
        presentAlert("Config Missing", body: "an app id and app key (or a jwt) is required in order to use the sample app. Please refer to the readme in the sample app repo for more information")
        //setActionRunning(false)
    }
    //
    //MARK: - Actions -
    //
    @IBAction func loginOutButtonTapped(_ sender: UIButton) {
        Kin.shared.logout()
        currentUserLabel.text = nil
        loginOutButton.setTitle("Login", for: .normal)
        UserDefaults.standard.removeObject(forKey: "SALastUser")
        uiState = .onlyLogin
        if sender.titleLabel?.text == "Login" {
             uiState = .disabled
             presentLogin(animated: true)
        }
    }
    @IBAction func buyStickerTapped(_ sender: Any) {
        externalOfferTapped(false)
    }
    @IBAction func requestPaymentTapped(_ sender: Any) {
        externalOfferTapped(true)
    }
    @IBAction func continueTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Select experience", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Marketplace", style: .default, handler: { _ in
            try? Kin.shared.launchEcosystem(from: self)
        }))
        alert.addAction(UIAlertAction(title: "History", style: .default, handler: { _ in
            try? Kin.shared.launchEcosystem(from: self, at: .history)
        }))
        alert.addAction(UIAlertAction(title: "Backup", style: .default, handler: { _ in
            try? Kin.shared.launchEcosystem(from: self, at: .backup({ completed in
                print("Backup \(completed)")
            }))
        }))
        alert.addAction(UIAlertAction(title: "Restore", style: .default, handler: { _ in
            try? Kin.shared.launchEcosystem(from: self, at: .restore({ completed in
                print("Restore \(completed)")
            }))
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func startKin() {
        
        do {
            try jwtLogin()
        } catch {
            alertStartError(error)
        }
        let sOffer = NativeOffer(id: "NSOffer_01",
                                title: "Buy this!",
                                description: "It's amazing",
                                amount: 1000,
                                image: "https://s3.amazonaws.com/assets.kinecosystembeta.com/images/spend_test.png",
                                offerType: .spend,
                                isModal: true)
        let eOffer = NativeOffer(id: "NEOffer_01",
                                 title: "Get Kin!",
                                 description: "It's Free!",
                                 amount: 10,
                                 image: "https://s3.amazonaws.com/assets.kinecosystembeta.com/images/native_earn_padding.png",
                                 offerType: .earn,
                                 isModal: true)
        do {
            try Kin.shared.add(nativeOffer: sOffer)
            try Kin.shared.add(nativeOffer: eOffer)
        } catch {
            print("failed to add native offer, error: \(error)")
        }

        Kin.shared.nativeOfferHandler = { offer in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Native Offer", message: "You tapped a native offer and the handler was invoked.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Close", style: .cancel))
                let presentor = self.presentedViewController ?? self
                presentor.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func presentLogin(animated: Bool) {
        let pt = self.storyboard!.instantiateViewController(withIdentifier: "TargetUserViewController") as! TargetUserViewController
        pt.title = "Login"
        
        pt.selectBlock = { [weak self] userId in
            guard let this = self else { return }
            //self?.currentUserLabel.text = lastUser
            defer {
                if let userId = userId {
                    UserDefaults.standard.set(userId, forKey: "SALastUser")
                    try? this.jwtLogin() { error in
                        self?.uiState = Kin.shared.isLoggedIn ? .enabled : .onlyLogin
                        // this.setActionRunning(false)
                        if let e = error {
                            this.presentAlert("Login failed", body: "error: \(e.localizedDescription)")
                        }
                    }
                }
                else {
                    self?.uiState = .onlyLogin
                }
                
            }
            this.dismiss(animated: true)
        }
        let nc = UINavigationController(rootViewController: pt)
        self.present(nc, animated: animated)
    }
    
    func jwtLogin(callback: KinLoginCallback? = nil) throws {
        print(Kin.shared.isLoggedIn)
        guard let user = lastUser else {
            loginOutButton.setTitle("Login", for: .normal)
            uiState = .onlyLogin
            presentLogin(animated: true)
            return
        }
        guard  let jwtPKey = privateKey,
                let id = appId else {
            alertConfigIssue()
            return
        }
        
        guard let encoded = JWTUtil.encode(header: ["alg": "RS512",
                                                    "typ": "jwt",
                                                    "kid" : kid],
                                           body: ["user_id": user,
                                                  "device_id": deviceId],
                                           subject: "register",
                                           id: id, privateKey: jwtPKey) else {
                                            alertConfigIssue()
                                            return
        }
       //  setActionRunning(true)
        self.uiState = .disabled
        try Kin.shared.start(environment: environment)
        try Kin.shared.login(jwt: encoded) { [weak self] e in
            DispatchQueue.main.async {
                self?.uiState = Kin.shared.isLoggedIn ? .enabled : .onlyLogin
                self?.currentUserLabel.text = self?.lastUser
                self?.loginOutButton.setTitle("Logout", for: .normal)
              //  self?.setActionRunning(false)
                callback?(e)
            }
        }
    }
    
    fileprivate func alertStartError(_ error: Error) {
        let alert = UIAlertController(title: "Start failed", message: "Error: \(error)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Oh ok", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
   

    private var giftingUserId: String?

    @IBAction func payToUserTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Gift / Pay to User", message: nil, preferredStyle: .alert)

        let giftAction = UIAlertAction(title: "Gift", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first, let userId = textField.text, let strongSelf = self else {
                self?.alertConfigIssue()
                return
            }

            strongSelf.giftingUserId = userId

            Kin.giftingManager.delegate = strongSelf
            Kin.giftingManager.present(in: strongSelf)
        }
        let payAction = UIAlertAction(title: "Pay", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first, let userId = textField.text else {
                return
            }

            self?.payToUserId(userId)
        }
        alertController.addTextField { textField in
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main, using: { _ in
                let hasText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).count ?? 0 > 0

                giftAction.isEnabled = hasText
                payAction.isEnabled = hasText
            })
        }

        giftAction.isEnabled = false
        payAction.isEnabled = false

        alertController.addAction(giftAction)
        alertController.addAction(payAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }

    @IBAction func userStats(_ sender: Any) {
        Kin.shared.userStats { [weak self] stats, error in
            if let result = stats {
                self?.presentAlert("User Stats", body: result.description)
            } else if let err = error {
                self?.presentAlert("Error", body: err.localizedDescription)
            } else {
                self?.presentAlert("Error", body: "Unknown Error")
            }
        }
    }
    
    fileprivate func externalOfferTapped(_ earn: Bool) {
        guard   let id = appId,
                let jwtPKey = privateKey else {
                alertConfigIssue()
                return
        }
        if Kin.shared.isActivated == false {
            do {
                try jwtLogin()
            } catch {
                alertStartError(error)
                return
            }
        }
        let offerID = "WOWOMGCRAZY"+"\(arc4random_uniform(999999))"
        var encoded: String? = nil
        if earn {
            encoded = JWTUtil.encode(header: ["alg": "RS512",
                                              "typ": "jwt",
                                              "kid" : kid],
                                     body: ["offer":["id":offerID, "amount":99],
                                            "recipient": ["title":"Give me Kin",
                                                          "description":"A native earn example",
                                                          "user_id":lastUser,
                                                          "device_id": deviceId]],
                                     subject: "earn",
                                     id: id, privateKey: jwtPKey)
        } else {
            encoded = JWTUtil.encode(header: ["alg": "RS512",
                                                    "typ": "jwt",
                                                    "kid" : kid],
                                           body: ["offer":["id":offerID, "amount":10],
                                                  "sender": ["title":"Native Spend",
                                                             "description":"A native spend example",
                                                             "user_id":lastUser,
                                                             "device_id": deviceId]],
                                           subject: "spend",
                                           id: id, privateKey: jwtPKey)
        }
        guard let encodedJWT = encoded else {
            alertConfigIssue()
            return
        }
        uiState = .disabled
       // setActionRunning(true)
        let handler: KinCallback = { jwtConfirmation, error in
            DispatchQueue.main.async { [weak self] in
                //self?.setActionRunning(false)
                self?.uiState = .enabled
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                if let confirm = jwtConfirmation {
                    alert.title = "Success"
                    alert.message = "\(earn ? "Earn" : "Purchase") complete. You can view the confirmation on jwt.io"
                    alert.addAction(UIAlertAction(title: "View on jwt.io", style: .default) { _ in
                        UIApplication.shared.openURL(URL(string:"https://jwt.io/#debugger-io?token=\(confirm)")!)
                    })
                } else if let e = error {
                    alert.title = "Failure"
                    alert.message = "\(earn ? "Earn" : "Purchase") failed (\(e.localizedDescription))"
                }
                
                alert.addAction(UIAlertAction(title: "Close", style: .cancel))
                
                self?.present(alert, animated: true, completion: nil)
            }
        }
        if earn {
            _ = Kin.shared.requestPayment(offerJWT: encodedJWT, completion: handler)
        } else {
            _ = Kin.shared.purchase(offerJWT: encodedJWT, completion: handler)
        }
    }
    
    func payToUserId(_ uid: String, amount: Decimal = 10) {
        guard   let id = appId,
            let jwtPKey = privateKey else {
                alertConfigIssue()
                return
        }
        if Kin.shared.isActivated == false {
            do {
                try jwtLogin()
            } catch {
                alertStartError(error)
                return
            }
        }
        
        Kin.shared.hasAccount(peer: uid) { [weak self] response, error in
            if let response = response {
                guard response else {
                    self?.presentAlert("User Not Found", body: "User \(uid) could not be found. Make sure the receiving user has activated kin, and in on the same environment as this user")
                    return
                }
                self?.transferKin(to: uid, appId: id, pKey: jwtPKey, amount: amount)
            } else if let error = error {
                self?.presentAlert("An Error Occurred", body: "\(error.localizedDescription)")
            } else {
                self?.presentAlert("An Error Occurred", body: "unknown error")
            }
        }
        
    }
    
    fileprivate func presentAlert(_ title: String, body: String?) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Oh ok", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }

    fileprivate func buildJWT(from: String, to: String, appId: String, pKey: String, amount: Decimal) -> String? {
        let offerID = "WOWOMGP2P"+"\(arc4random_uniform(999999))"

        return JWTUtil.encode(header: ["alg": "RS512",
                                       "typ": "jwt",
                                       "kid" : kid],
                              body: ["offer":["id":offerID, "amount":amount],
                                     "sender": ["title":"Pay to \(to)",
                                        "description":"Kin transfer to \(to)",
                                        "user_id":lastUser,
                                        "device_id": deviceId],
                                     "recipient": ["title":"\(from) paid you",
                                        "description":"Kin transfer from \(from)",
                                        "user_id":to]],
                              subject: "pay_to_user",
                              id: appId,
                              privateKey: pKey)
    }
    
    fileprivate func transferKin(to: String, appId: String, pKey: String, amount: Decimal) {
        guard let user = lastUser else {
            presentAlert("Not logged in", body: "try logging in.")
            return
        }

        guard let encoded = buildJWT(from: user, to: to, appId: appId, pKey: pKey, amount: amount) else {
            alertConfigIssue()
            return
        }

        uiState = .disabled
       // setActionRunning(true)
        let handler: KinCallback = { jwtConfirmation, error in
            DispatchQueue.main.async { [weak self] in
                self?.uiState = .enabled
                //self?.setActionRunning(false)
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                if let confirm = jwtConfirmation {
                    alert.title = "Success"
                    alert.message = "Payment complete. You can view the confirmation on jwt.io"
                    alert.addAction(UIAlertAction(title: "View on jwt.io", style: .default) { _ in
                        UIApplication.shared.openURL(URL(string:"https://jwt.io/#debugger-io?token=\(confirm)")!)
                    })
                } else if let e = error {
                    alert.title = "Failure"
                    alert.message = "Payment failed (\(e.localizedDescription))"
                }
                
                alert.addAction(UIAlertAction(title: "Close", style: .cancel))
                
                self?.present(alert, animated: true, completion: nil)
            }
        }
        
        _ = Kin.shared.payToUser(offerJWT: encoded, completion: handler)
        
    }
    
//    func setActionRunning(_ value: Bool) {
//
////        loginOutButton.isEnabled = !value
////        buyStickerButton.isEnabled = !value
////        getKinButton.isEnabled = !value
////        payButton.isEnabled = !value
////        loginOutButton.alpha = value ? 0.3 : 1.0
////        buyStickerButton.alpha = value ? 0.3 : 1.0
////        getKinButton.alpha = value ? 0.3 : 1.0
////        payButton.alpha = value ? 0.3 : 1.0
//        value ? externalIndicator.startAnimating() : externalIndicator.stopAnimating()
//    }
}

extension SampleAppViewController: GiftingManagerDelegate {
    func giftingManagerDidPresent(_ giftingManager: GiftingManager) {

    }

    func giftingManagerDidCancel(_ giftingManager: GiftingManager) {

    }

    func giftingManagerNeedsJWT(_ giftingManager: GiftingManager, amount: Decimal) -> String? {
        guard let user = lastUser else {
            presentAlert("Not logged in", body: "try logging in.")
            return nil
        }

        guard let appId = appId, let pKey = privateKey, let userId = giftingUserId else {
            alertConfigIssue()
            return nil
        }

        return buildJWT(from: user, to: userId, appId: appId, pKey: pKey, amount: amount)
    }

    func giftingManager(_ giftingManager: GiftingManager, didCompleteWith jwtConfirmation: String) {

    }

    func giftingManager(_ giftingManager: GiftingManager, error: Error) {

    }
}
