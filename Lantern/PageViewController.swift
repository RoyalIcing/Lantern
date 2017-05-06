//
//	PageViewController.swift
//	Hoverlytics for Mac
//
//	Created by Patrick Smith on 29/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import WebKit
import LanternModel
import BurntFoundation


typealias PageViewControllerGoogleOAuth2TokenCallback = (_ tokenJSONString: String) -> ()


open class PageViewController: NSViewController {
	var splitViewController: NSSplitViewController!
	
	@IBOutlet var URLField: NSTextField!
	@IBOutlet var crawlWhileBrowsingCheckButton: NSButton!
	var webViewController: PageWebViewController! {
		didSet {
			prepareWebViewController(webViewController!)
		}
	}
	
	
	var crawlWhileBrowsing: Bool = true
	
	var GoogleOAuth2TokenJSONString: String?
	var hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback: PageViewControllerGoogleOAuth2TokenCallback?
	
	// TODO: remove
	var navigatedURLDidChangeCallback: ((_ URL: URL) -> ())?
	
	let minimumWidth: CGFloat = 600.0
	let minimumHeight: CGFloat = 200.0
	
	var preferredBrowserWidth: CGFloat? {
		didSet {
			if let webViewController = webViewController {
				webViewController.preferredBrowserWidth = preferredBrowserWidth
			}
		}
	}
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		
		view.addConstraint(NSLayoutConstraint(item: view, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: minimumWidth))
		view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: minimumHeight))
	}
	
	var webViewControllerNotificationObserver: NotificationObserver<PageWebViewControllerNotification>!
	//var webViewControllerNotificationObservers = [PageWebViewControllerNotification: AnyObject]()
	
	func startObservingWebViewController() {
		webViewControllerNotificationObserver = NotificationObserver<PageWebViewControllerNotification>(object: webViewController)
		webViewControllerNotificationObserver.observe(.URLDidChange) { [weak self] _ in
			self?.navigatedURLDidChange()
		}
	}
	
	func prepareWebViewController(_ webViewController: PageWebViewController) {
		#if false
			webViewController.wantsHoverlyticsScript = true
			webViewController.GoogleOAuth2TokenJSONString = GoogleOAuth2TokenJSONString
			webViewController.hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback = hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback
		#endif
		webViewController.prepare()
		
		webViewController.preferredBrowserWidth = preferredBrowserWidth
		
		startObservingWebViewController()
	}
	
	// MARK: Segue
	
	override open func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		/*if segue.identifier == "webViewController" {
			webViewController = segue.destinationController as! PageWebViewController
			prepareWebViewController(webViewController)
		}*/
		if segue.identifier == "activeResourceSplit" {
			let splitVC = segue.destinationController as! NSSplitViewController
			self.splitViewController = splitVC
			let webSplit = splitVC.splitViewItems[0]
			webViewController = webSplit.viewController as! PageWebViewController
		}
	}
	
	func navigatedURLDidChange() {
		// FIXME: ask web view controller
		guard let url = pageMapperProvider?.activeURL else { return }
		
		navigatedURLDidChangeCallback?(url)
		
		updateUIForURL(url)
	}
	
	func loadURL(_ URL: Foundation.URL) {
		webViewController.loadURL(URL)
		
		updateUIForURL(URL)
	}
	
	func updateUIForURL(_ URL: Foundation.URL) {
		URLField.stringValue = URL.absoluteString
	}
	
	// MARK: Actions
	
	@IBAction func URLFieldChanged(_ textField: NSTextField) {
		if let URL = LanternModel.detectWebURL(fromString: textField.stringValue) {
			loadURL(URL)
		}
	}
	
	@IBAction func toggleCrawlWhileBrowsing(_ checkButton: NSButton) {
		let on = checkButton.state == NSOnState
		crawlWhileBrowsing = on
	}
	
	@IBAction func reloadBrowsing(_ sender: AnyObject?) {
		webViewController.reloadFromOrigin()
	}
	
	enum ShowToggleSegment : Int {
		case browser = 1
		case info = 2
	}
	
	@IBAction func toggleShownViews(_ sender: Any?) {
		guard
			let control = sender as? NSSegmentedControl,
			let cell = control.cell as? NSSegmentedCell
			else { return }
		
		let splitViewItems = splitViewController.splitViewItems
		(0 ..< cell.segmentCount).forEach() { segmentIndex in
			let show = cell.isSelected(forSegment: segmentIndex)
			splitViewItems[segmentIndex].isCollapsed = !show
		}
	}
}


enum PageWebViewControllerNotification: String {
	case URLDidChange = "HoverlyticsApp.PageWebViewControllerNotification.URLDidChange"
	
	var notificationName: String {
		return self.rawValue
	}
}

enum MessageIdentifier: String {
	case receiveWindowClose = "windowDidClose"
	case googleAPIAuthorizationChanged = "googleAPIAuthorizationChanged"
	case console = "console"
}

private var webViewURLObservingContext = 0

class PageWebViewController : NSViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
	var webViewConfiguration = WKWebViewConfiguration()
	var wantsHoverlyticsScript = false
	var allowsClosing = false
	fileprivate(set) var webView: WKWebView!
	var URL: Foundation.URL!
	var hoverlyticsPanelDocumentReadyCallback: (() -> ())?
	var GoogleOAuth2TokenJSONString: String?
	var hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback: PageViewControllerGoogleOAuth2TokenCallback?
	
	fileprivate var preferredBrowserWidthContraint: NSLayoutConstraint?
	fileprivate var minimumWidthContraint: NSLayoutConstraint?
	var preferredBrowserWidth: CGFloat? {
		didSet {
			if let preferredBrowserWidthContraint = preferredBrowserWidthContraint {
				view.removeConstraint(preferredBrowserWidthContraint)
				self.preferredBrowserWidthContraint = nil
			}
			
			if let preferredBrowserWidth = preferredBrowserWidth {
				let constraint = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: preferredBrowserWidth)
				view.addConstraint(constraint)
				preferredBrowserWidthContraint = constraint
			}
		}
	}
	
	func prepare() {
		let preferences = WKPreferences()
		preferences.javaEnabled = false
		preferences.plugInsEnabled = false
		#if DEBUG
			preferences.setValue(true, forKey: "developerExtrasEnabled")
		#endif
		webViewConfiguration.preferences = preferences
		
		let userContentController = webViewConfiguration.userContentController
		
		func addBundledUserScript(_ scriptNameInBundle: String, injectAtStart: Bool = false, injectAtEnd: Bool = false, forMainFrameOnly: Bool = true, sourceReplacements: [String:String]? = nil) {
			let scriptURL = Bundle.main.url(forResource: scriptNameInBundle, withExtension: "js")!
			let scriptSource = try! NSMutableString(contentsOf: scriptURL, usedEncoding: nil)
			
			if let sourceReplacements = sourceReplacements {
				func replaceInTemplate(find target: String, replace replacement: String) {
					scriptSource.replaceOccurrences(of: target, with: replacement, options: NSString.CompareOptions(rawValue: 0), range: NSMakeRange(0, scriptSource.length))
				}
				
				for (placeholderID, value) in sourceReplacements {
					replaceInTemplate(find: placeholderID, replace: value)
				}
			}
			
			if injectAtStart {
				let script = WKUserScript(source: scriptSource as String, injectionTime: .atDocumentStart, forMainFrameOnly: forMainFrameOnly)
				userContentController.addUserScript(script)
			}
			
			if injectAtEnd {
				let script = WKUserScript(source: scriptSource as String, injectionTime: .atDocumentEnd, forMainFrameOnly: forMainFrameOnly)
				userContentController.addUserScript(script)
			}
		}
		
		addBundledUserScript("console", injectAtStart: true)
		userContentController.add(self, name: "console")
		
		if true {
			addBundledUserScript("userAgent", injectAtStart: true)
		}
		
		if allowsClosing {
			addBundledUserScript("windowClose", injectAtStart: true)
			
			userContentController.add(self, name: MessageIdentifier.receiveWindowClose.rawValue)
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
			
			userContentController.add(self, name: MessageIdentifier.googleAPIAuthorizationChanged.rawValue)
		}
			
		webViewConfiguration.userContentController = userContentController
		
		webView = WKWebView(frame: NSRect.zero, configuration: webViewConfiguration)
		webView.navigationDelegate = self
		webView.uiDelegate = self
		webView.allowsBackForwardNavigationGestures = true
		
		if true {
			// Required by TypeKit to serve the correct fonts.
			webView.setValue("Safari/600.4.10", forKey: "applicationNameForUserAgent")
		}
		
		//fillViewWithChildView(webView)
		view.addSubview(webView)
		
		webView.translatesAutoresizingMaskIntoConstraints = false
		
		let minimumWidthContraint = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: view, attribute: .width, multiplier: 1.0, constant: 0.0)
		minimumWidthContraint.priority = 750
		view.addConstraint(
			minimumWidthContraint
		)
		self.minimumWidthContraint = minimumWidthContraint
		
		addLayoutConstraint(toMatch: .width, withChildView:webView, identifier:"width", priority: 250)
		addLayoutConstraint(toMatch: .height, withChildView:webView, identifier:"height")
		addLayoutConstraint(toMatch: .centerX, withChildView:webView, identifier:"centerX")
		addLayoutConstraint(toMatch: .top, withChildView:webView, identifier:"top")
		
		webView.addObserver(self, forKeyPath: "URL", options: .new, context: &webViewURLObservingContext)
		
		view.wantsLayer = true
		view.layer?.backgroundColor = NSColor.black.cgColor
	}
	
	deinit {
		webView.removeObserver(self, forKeyPath: "URL", context: &webViewURLObservingContext)
	}
	
	func loadURL(_ url: Foundation.URL) {
		self.URL = url
		
		webView.load(URLRequest(url: url))
	}
	
	func reloadFromOrigin() {
		webView.reloadFromOrigin()
	}
	
	fileprivate func mainQueue_notify(_ identifier: PageWebViewControllerNotification, userInfo: [String:AnyObject]? = nil) {
		let nc = NotificationCenter.default
		nc.post(name: Notification.Name(rawValue: identifier.notificationName), object: self, userInfo: userInfo)
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let keyPath = keyPath else { return }
		
		if context == &webViewURLObservingContext {
			switch keyPath {
			//case #keyPath(WKWebView.url):
			case "URL":
				pageMapperProvider?.activeURL = webView.url
			default:
				break
			}
		}
		else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	// MARK: WKNavigationDelegate
	
	/*
	func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> ()) {
		switch navigationAction.navigationType {
		case .LinkActivated, .BackForward, .Other:
			if navigationAction.targetFrame?.mainFrame ?? false {
				let request = navigationAction.request
				if let URL = request.URL {
					didNavigateToURL(URL)
				}
			}
		default:
			break
		}
		
		decisionHandler(.Allow)
	}
	*/
	/*
	func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> ()) {
		
	}
	*/
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		#if DEBUG
			print("didFinishNavigation \(navigation)")
		#endif
	}
	
	// MARK: WKUIDelegate
	
	func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
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
	
	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		if let messageIdentifier = MessageIdentifier(rawValue: message.name) {
			switch messageIdentifier {
			case .receiveWindowClose:
				if allowsClosing {
					dismiss(nil)
				}
			case .googleAPIAuthorizationChanged:
				if let body = message.body as? [String:AnyObject] {
					if body["googleClientAPILoaded"] != nil {
						//println("googleClientAPILoaded \(body)")
					}
					else if let tokenJSONString = body["tokenJSONString"] as? String {
						hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback?(tokenJSONString)
						#if DEBUG
							print("tokenJSONString \(tokenJSONString)")
						#endif
					}
				}
			case .console:
				#if DEBUG && false
					println("CONSOLE")
					if let messageBody = message.body as? [String: AnyObject] {
						println("CONSOLE \(messageBody)")
					}
				#endif
			}
		}
		else {
			print("Unhandled script message \(message.name)")
		}
	}
	
}
