//
//  EarnOfferViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 15/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import WebKit
import CoreDataStack
import KinUtil

enum JSFunctions: String {
    case handleResult
    case handleCancel
    case loaded
}

enum EarnOfferHTMLError: Error {
    case userCanceled
    case invalidJSResult
    case js(Error)
}

class EarnOfferViewController: UIViewController {

    var web: WKWebView!
    var offerId: String?
    var core: Core!
    fileprivate(set) var earn = Promise<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: JSFunctions.handleResult.rawValue)
        contentController.add(self, name: JSFunctions.handleCancel.rawValue)
        contentController.add(self, name: JSFunctions.loaded.rawValue)
        config.userContentController = contentController
        web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = self
        web.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(web)
        web.fillSuperview()
        web.layoutIfNeeded()
        var request = URLRequest(url: URL(string: "http://htmlpoll.kinecosystem.com.s3-website-us-east-1.amazonaws.com")!)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        web.load(request)
    }
    
    func loadContent() {
        guard let oid = offerId else {
            logError("webview didn't receive any offer to load when presented")
            return
        }
        core.data.objects(of: Offer.self, with: NSPredicate(with: ["id" : oid])).then { result in
            guard let offer = result.first else {
                logError("failed to fetch order given to html controller from store")
                return
            }
            let content = offer.content
            DispatchQueue.main.async {
                self.web.evaluateJavaScript("window.kin.renderPoll(\(content))") { result, error in
                    if let error = error {
                        self.earn.signal(EarnOfferHTMLError.js(error))
                    }
                }
            }
            
        }
    }
}

extension EarnOfferViewController: WKScriptMessageHandler, WKNavigationDelegate {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        logInfo("got messgae: \(message.name)")
        switch message.name {
        case JSFunctions.loaded.rawValue:
            loadContent()
        case JSFunctions.handleResult.rawValue:
            guard   JSONSerialization.isValidJSONObject(message.body),
                let json = try? JSONSerialization.data(withJSONObject: message.body, options: []),
                    let jsonString = String(data: json, encoding: .utf8)?.replacingOccurrences(of: "\\\"", with: "\"") else {
                earn.signal(EarnOfferHTMLError.invalidJSResult)
                        return
            }
            earn.signal(jsonString)
        case JSFunctions.handleCancel.rawValue:
            earn.signal(EarnOfferHTMLError.userCanceled)
        default:
            logWarn("unhandled webkit message received: \(message)")
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
}

