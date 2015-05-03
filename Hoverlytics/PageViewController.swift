//
//  PageViewController.swift
//  Hoverlytics for Mac
//
//  Created by Patrick Smith on 29/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import WebKit
import HoverlyticsModel


typealias PageViewControllerGoogleOAuth2TokenCallback = (tokenJSONString: String) -> Void


class PageViewController: NSViewController {
	@IBOutlet var URLField: NSTextField!
	@IBOutlet var crawlWhileBrowsingCheckButton: NSButton!
	var webViewController: PageWebViewController!
	
	
	var crawlWhileBrowsing: Bool = true
	
	var GoogleOAuth2TokenJSONString: String?
	var hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback: PageViewControllerGoogleOAuth2TokenCallback?
	
	var navigatedURLDidChangeCallback: ((URL: NSURL) -> Void)?
	
	let minimumWidth: CGFloat = 600.0
	let minimumHeight: CGFloat = 200.0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.addConstraint(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: minimumWidth))
		view.addConstraint(NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: minimumHeight))
	}
	
	var webViewControllerNotificationObservers = [PageWebViewControllerNotification: AnyObject]()
	
	func startObservingWebViewController() {
		let nc = NSNotificationCenter.defaultCenter()
		let mainQueue = NSOperationQueue.mainQueue()
		
		func addObserver(notificationIdentifier: PageWebViewControllerNotification, block: (NSNotification!) -> Void) {
			let observer = nc.addObserverForName(notificationIdentifier.notificationName, object: webViewController, queue: mainQueue, usingBlock: block)
			webViewControllerNotificationObservers[notificationIdentifier] = observer
		}
		
		addObserver(.URLDidChange) { (notification) in
			self.navigatedURLDidChange(self.webViewController.URL)
		}
	}
	
	func stopObservingWebViewController() {
		let nc = NSNotificationCenter.defaultCenter()
		
		for (notificationIdentifier, observer) in webViewControllerNotificationObservers {
			nc.removeObserver(observer)
		}
		webViewControllerNotificationObservers.removeAll(keepCapacity: false)
	}
	
	func prepareWebViewController(webViewController: PageWebViewController) {
		#if false
			webViewController.wantsHoverlyticsScript = true
			webViewController.GoogleOAuth2TokenJSONString = GoogleOAuth2TokenJSONString
			webViewController.hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback = hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback
		#endif
		webViewController.prepare()
		
		startObservingWebViewController()
	}
	
	override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "webViewController" {
			webViewController = segue.destinationController as! PageWebViewController
			prepareWebViewController(webViewController)
		}
	}
	
	func navigatedURLDidChange(URL: NSURL) {
		navigatedURLDidChangeCallback?(URL: URL)
		
		updateUIForURL(URL)
	}
	
	func loadURL(URL: NSURL) {
		webViewController.loadURL(URL)
		
		updateUIForURL(URL)
	}
	
	func updateUIForURL(URL: NSURL) {
		URLField.stringValue = URL.absoluteString!
	}
	
	@IBAction func URLFieldChanged(textField: NSTextField) {
		if let URL = HoverlyticsModel.detectWebURL(fromString: textField.stringValue) {
			loadURL(URL)
		}
	}
	
	@IBAction func toggleCrawlWhileBrowsing(checkButton: NSButton) {
		let on = checkButton.state == NSOnState
		crawlWhileBrowsing = on
	}
	
	@IBAction func reloadBrowsing(sender: AnyObject?) {
		webViewController.reloadFromOrigin()
	}
}


enum PageWebViewControllerNotification: String {
	case URLDidChange = "HoverlyticsApp.PageWebViewControllerNotification.URLDidChange"
	
	var notificationName: String {
		return self.rawValue
	}
}


let PageWebViewController_receiveWindowCloseMessageIdentifier = "windowDidClose"
let PageWebViewController_googleAPIAuthorizationChangedMessageIdentifier = "googleAPIAuthorizationChanged"

private var webViewURLObservingContext = 0

class PageWebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
	var webViewConfiguration = WKWebViewConfiguration()
	var wantsHoverlyticsScript = false
	var allowsClosing = false
	private(set) var webView: WKWebView!
	var URL: NSURL!
	var hoverlyticsPanelDocumentReadyCallback: (() -> Void)?
	var GoogleOAuth2TokenJSONString: String?
	var hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback: PageViewControllerGoogleOAuth2TokenCallback?
	
	func prepare() {
		let preferences = WKPreferences()
		preferences.javaEnabled = false
		preferences.plugInsEnabled = false
		#if DEBUG
			preferences.setValue(true, forKey: "developerExtrasEnabled")
		#endif
		webViewConfiguration.preferences = preferences
		
		let userContentController = webViewConfiguration.userContentController ?? WKUserContentController()
		
		func addBundledUserScript(scriptNameInBundle: String, injectAtStart: Bool = false, injectAtEnd: Bool = false, forMainFrameOnly: Bool = true, sourceReplacements: [String:String]? = nil) {
			let scriptURL = NSBundle.mainBundle().URLForResource(scriptNameInBundle, withExtension: "js")!
			let scriptSource = NSMutableString(contentsOfURL: scriptURL, usedEncoding: nil, error: nil)!
			
			if let sourceReplacements = sourceReplacements {
				func replaceInTemplate(find target: String, replace replacement: String) {
					scriptSource.replaceOccurrencesOfString(target, withString: replacement, options: NSStringCompareOptions(0), range: NSMakeRange(0, scriptSource.length))
				}
				
				for (placeholderID, value) in sourceReplacements {
					replaceInTemplate(find: placeholderID, replace: value)
				}
			}
			
			if injectAtStart {
				let script = WKUserScript(source: scriptSource as String, injectionTime: .AtDocumentStart, forMainFrameOnly: forMainFrameOnly)
				userContentController.addUserScript(script)
			}
			
			if injectAtEnd {
				let script = WKUserScript(source: scriptSource as String, injectionTime: .AtDocumentEnd, forMainFrameOnly: forMainFrameOnly)
				userContentController.addUserScript(script)
			}
		}
		
		addBundledUserScript("console", injectAtStart: true)
		userContentController.addScriptMessageHandler(self, name: "console")
		
		if true {
			addBundledUserScript("userAgent", injectAtStart: true)
		}
		
		if allowsClosing {
			addBundledUserScript("windowClose", injectAtStart: true)
			
			userContentController.addScriptMessageHandler(self, name: PageWebViewController_receiveWindowCloseMessageIdentifier)
		}
		
		if wantsHoverlyticsScript {
			addBundledUserScript("insertHoverlytics", injectAtEnd: true)
			
			#if true
				let tokenJSONString: String? = GoogleOAuth2TokenJSONString
				
				if let tokenJSONString = tokenJSONString {
					addBundledUserScript("setPanelAuthorizationToken", injectAtEnd: true, forMainFrameOnly: false, sourceReplacements: [
						"__TOKEN__": tokenJSONString
						])
				}
			#endif
			
			addBundledUserScript("panelAuthorizationChanged", injectAtEnd: true, forMainFrameOnly: false)
			
			userContentController.addScriptMessageHandler(self, name: PageWebViewController_googleAPIAuthorizationChangedMessageIdentifier)
		}
			
		webViewConfiguration.userContentController = userContentController
		
		webView = WKWebView(frame: NSRect.zeroRect, configuration: webViewConfiguration)
		webView.navigationDelegate = self
		webView.UIDelegate = self
		webView.allowsBackForwardNavigationGestures = true
		
		if true {
			// Required by TypeKit to serve the correct fonts.
			webView.setValue("Safari/600.4.10", forKey: "applicationNameForUserAgent")
		}
		
		self.fillViewWithChildView(webView)
		
		webView.addObserver(self, forKeyPath: "URL", options: .New, context: &webViewURLObservingContext)
	}
	
	deinit {
		webView.removeObserver(self, forKeyPath: "URL", context: &webViewURLObservingContext)
	}
	
	func loadURL(URL: NSURL) {
		self.URL = URL
		
		let URLRequest = NSURLRequest(URL: URL)
		webView.loadRequest(URLRequest)
	}
	
	func reloadFromOrigin() {
		webView.reloadFromOrigin()
	}
	
	private func mainQueue_notify(identifier: PageWebViewControllerNotification, userInfo: [String:AnyObject]? = nil) {
		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(identifier.notificationName, object: self, userInfo: userInfo)
	}
	
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
		if context == &webViewURLObservingContext {
			switch keyPath {
			case "URL":
				self.URL = webView.URL
				mainQueue_notify(.URLDidChange)
			default:
				break
			}
		}
		else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	
	// MARK: WKNavigationDelegate
	
	func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
		// FIXME: Error with navigation.request for some reason
		let request = navigation.valueForKey("request") as! NSURLRequest
		self.URL = request.URL
		mainQueue_notify(.URLDidChange)
	}
	/*
	func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
		//println("navigationAction \(navigationAction.navigationType) \(navigationAction)")
		
		decisionHandler(.Allow)
	}
	*/
	func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		#if DEBUG
			println("didFinishNavigation \(navigation)")
		#endif
	}
	
	// MARK: WKUIDelegate
	
	func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
		let innerPageViewController = PageWebViewController(nibName: nil, bundle: nil)!
		innerPageViewController.view = NSView(frame: NSRect(x: 0, y: 0, width: 500.0, height: 500.0))
		
		configuration.userContentController = WKUserContentController()
		innerPageViewController.webViewConfiguration = configuration
		innerPageViewController.wantsHoverlyticsScript = false
		innerPageViewController.allowsClosing = true
		
		innerPageViewController.prepare()
		
		// http://www.google.com/analytics/
		presentViewControllerAsSheet(innerPageViewController)
		
		return innerPageViewController.webView
	}
	
	// MARK: WKScriptMessageHandler
	
	func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		if message.name == PageWebViewController_receiveWindowCloseMessageIdentifier {
			if allowsClosing {
				dismissController(nil)
			}
		}
		else if message.name == PageWebViewController_googleAPIAuthorizationChangedMessageIdentifier {
			if let body = message.body as? [String:AnyObject] {
				if body["googleClientAPILoaded"] != nil {
					//println("googleClientAPILoaded \(body)")
				}
				else if let tokenJSONString = body["tokenJSONString"] as? String {
					hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback?(tokenJSONString: tokenJSONString)
					#if DEBUG
						println("tokenJSONString \(tokenJSONString)")
					#endif
				}
			}
		}
		else if message.name == "console" {
			#if DEBUG && false
			println("CONSOLE")
			if let messageBody = message.body as? [String: AnyObject] {
				println("CONSOLE \(messageBody)")
			}
			#endif
		}
		else {
			println("Unhandled script message \(message.name)")
		}
	}
	
}
