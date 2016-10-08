//
//	WKUserContentController+bundledScripts.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 22/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import WebKit


extension WKUserContentController {
	func addBundledUserScript(_ scriptNameInBundle: String, injectAtStart: Bool = false, injectAtEnd: Bool = false, forMainFrameOnly: Bool = true, sourceReplacements: [String:String]? = nil) {
		assert(injectAtStart || injectAtEnd, "User script must either be injected at start or at end. Add injectAtStart: true or injectAtEnd: true")
		
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
			self.addUserScript(script)
		}
		
		if injectAtEnd {
			let script = WKUserScript(source: scriptSource as String, injectionTime: .atDocumentEnd, forMainFrameOnly: forMainFrameOnly)
			self.addUserScript(script)
		}
	}
}
