//
//  PageViewController.swift
//  Hoverlytics for Mac
//
//  Created by Patrick Smith on 29/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import WebKit


class PageViewController: NSViewController {
	@IBOutlet internal var URLField: NSTextField!
	internal var webViewController: PageWebViewController!
	
	//var editorConfiguration: EditorConfiguration = EditorConfiguration.burntCaramelDevEditor
	
	var minimumWidth: CGFloat = 600.0
	var minimumHeight: CGFloat = 450.0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.addConstraint(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: minimumWidth))
		view.addConstraint(NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: minimumHeight))
	}
	
	func prepareWebViewController(webViewController: PageWebViewController) {
		webViewController.prepare()
	}
	
	override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "webViewController" {
			webViewController = segue.destinationController as PageWebViewController
			prepareWebViewController(webViewController)
		}
	}
	
	func detectWebURL(fromString URLString: String) -> NSURL? {
		var error: NSError?
		let dataDetector = NSDataDetector(types: NSTextCheckingType.Link.rawValue, error: &error)
		
		if let result = dataDetector?.firstMatchInString(URLString, options: NSMatchingOptions.allZeros, range: NSMakeRange(0, (URLString as NSString).length)) {
			return result.URL
		}
		else {
			return nil
		}
	}
	
	@IBAction func URLFieldChanged(sender: AnyObject?) {
		if let textField = sender as? NSTextField {
			if let URL = detectWebURL(fromString: textField.stringValue) {
				webViewController.loadURL(URL)
			}
		}
	}
}


let PageWebViewController_icingReceiveContentJSONMessageIdentifier = "icingReceiveContentJSON"

private var webViewURLObservingContext = 0

class PageWebViewController: NSViewController, WKNavigationDelegate, WKScriptMessageHandler {
	private var webView: WKWebView!
	var URL: NSURL!
	
	func prepare() {
		
		let preferences = WKPreferences()
		preferences.javaEnabled = false
		preferences.plugInsEnabled = false
		
		#if DEBUG
			preferences.setValue(true, forKey: "developerExtrasEnabled")
		#endif
		
		let webViewConfiguration = WKWebViewConfiguration()
		webViewConfiguration.preferences = preferences
		
		let userContentController = WKUserContentController()
		
		let hoverlyticsScriptURL = NSBundle.mainBundle().URLForResource("insertHoverlytics", withExtension: "js")!
		let insertHoverlyticsScriptSource = NSString(contentsOfURL: hoverlyticsScriptURL, usedEncoding: nil, error: nil)!
		let insertHoverlyticsScript = WKUserScript(source: insertHoverlyticsScriptSource, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
		userContentController.addUserScript(insertHoverlyticsScript)
		
		userContentController.addScriptMessageHandler(self, name: PageWebViewController_icingReceiveContentJSONMessageIdentifier)
		
		webViewConfiguration.userContentController = userContentController
		
		webView = WKWebView(frame: NSRect.zeroRect, configuration: webViewConfiguration)
		webView.navigationDelegate = self
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
	
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
		if context == &webViewURLObservingContext {
			switch keyPath {
			case "URL":
				self.URL = webView.URL
			default:
				break
			}
		}
		else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	
	@IBAction func reload(sender: AnyObject) {
		webView.reload()
	}
	
	func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
		// FIXME: Error with navigation.request for some reason
		let request = navigation.valueForKey("request") as NSURLRequest
		self.URL = request.URL
	}
	
	func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		#if DEBUG
			println("didFinishNavigation")
		#endif
		
	}
	
	func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		#if DEBUG
			println("didReceiveScriptMessage \(message)")
		#endif
		if message.name == PageWebViewController_icingReceiveContentJSONMessageIdentifier {
			if let messageBody = message.body as? [String: AnyObject] {
				if let contentJSON = messageBody["contentJSON"] as? [String: AnyObject] {
					//latestCopiedJSONData = NSJSONSerialization.dataWithJSONObject(contentJSON, options: NSJSONWritingOptions(0), error: nil)
				}
			}
		}
	}
	
}
