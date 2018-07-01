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
    case handleClose
    case loaded
    case displayTopBar
}

enum EarnOfferHTMLError: Error {
    case userCanceled
    case invalidJSResult
    case js(Error)
}

@available(iOS 9.0, *)
class EarnOfferViewController: KinViewController {

    var web: WKWebView!
    var offerId: String?
    var core: Core!
    fileprivate(set) var earn = Promise<String>()
    fileprivate var hideStatusBar = false

    let viewportScriptString = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); meta.setAttribute('initial-scale', '1.0'); meta.setAttribute('maximum-scale', '1.0'); meta.setAttribute('minimum-scale', '1.0'); meta.setAttribute('user-scalable', 'no'); document.getElementsByTagName('head')[0].appendChild(meta);"
    let disableSelectionScriptString = "document.documentElement.style.webkitUserSelect='none';"
    let disableCalloutScriptString = "document.documentElement.style.webkitTouchCallout='none';"

    override func viewDidLoad() {
        super.viewDidLoad()
        let item = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(userCanceled))
        item.tintColor = .white
        navigationItem.rightBarButtonItem = item
        view.backgroundColor = .white
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        let viewportScript = WKUserScript(source: viewportScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let disableSelectionScript = WKUserScript(source: disableSelectionScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let disableCalloutScript = WKUserScript(source: disableCalloutScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        contentController.add(self, name: JSFunctions.handleResult.rawValue)
        contentController.add(self, name: JSFunctions.handleCancel.rawValue)
        contentController.add(self, name: JSFunctions.loaded.rawValue)
        contentController.add(self, name: JSFunctions.handleClose.rawValue)
        contentController.add(self, name: JSFunctions.displayTopBar.rawValue)

        contentController.addUserScript(viewportScript)
        contentController.addUserScript(disableSelectionScript)
        contentController.addUserScript(disableCalloutScript)

        config.userContentController = contentController
        web = WKWebView(frame: .zero, configuration: config)
        web.scrollView.delaysContentTouches = false
        web.scrollView.isScrollEnabled = true
        web.scrollView.bounces = false
        web.allowsBackForwardNavigationGestures = false
        web.contentMode = .scaleToFill
        web.scrollView.delegate = self
        web.navigationDelegate = self
        web.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(web)
        web.fillSuperview()
        web.layoutIfNeeded()
        let request = URLRequest(url: URL(string: core.environment.webURL)!)
        web.load(request)
    }

    override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }

    func loadContent() {
        guard let oid = offerId else {
            logError("webview didn't receive any offer to load when presented")
            return
        }

        core.data.queryObjects(of: Offer.self, with: NSPredicate(with: ["id" : oid])) { result in
            guard let offer = result.first else {
                logError("failed to fetch order given to html controller from store")
                return
            }
            let contentType = offer.offerContentType
            let content = offer.content
            DispatchQueue.main.async {
                self.web.evaluateJavaScript("window.kin.renderPoll(\(content))") { result, error in
                    if let error = error {
                        self.earn.signal(EarnOfferHTMLError.js(error))
                    } else {
                        if let type = KBITypes.OfferType(rawValue: contentType.rawValue) {
                            Kin.track { try EarnPageLoaded(offerType: type) }
                        }
                    }
                }
            }

        }
    }

    @objc func userCanceled() {
        earn.signal(EarnOfferHTMLError.userCanceled)
        guard self.navigationController?.isBeingDismissed == false else { return }
        self.navigationController?.dismiss(animated: true)
    }
}


@available(iOS 9.0, *)
extension EarnOfferViewController: WKScriptMessageHandler, WKNavigationDelegate, UIScrollViewDelegate {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        logVerbose("got messgae: \(message.name)")
        switch message.name {
        case JSFunctions.loaded.rawValue:
            loadContent()
        case JSFunctions.handleResult.rawValue:
            guard let jsonString = (message.body as? NSArray)?.firstObject as? String else {
                        earn.signal(EarnOfferHTMLError.invalidJSResult)
                        self.navigationController?.dismiss(animated: true)
                        return
            }
            earn.signal(jsonString)
        case JSFunctions.handleCancel.rawValue:
            userCanceled()
        case JSFunctions.handleClose.rawValue:
            guard self.navigationController?.isBeingDismissed == false else { return }
            self.navigationController?.dismiss(animated: true)
        case JSFunctions.displayTopBar.rawValue:
            if let displayed = (message.body as? NSArray)?.firstObject as? Bool {
                self.navigationController?.setNavigationBarHidden(!displayed, animated: true)
                hideStatusBar = !displayed
                setNeedsStatusBarAppearanceUpdate()
            }
        default:
            logWarn("unhandled webkit message received: \(message)")
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}
