//
//  WKUserContentController+bundledScripts.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 22/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import WebKit


extension WKUserContentController {
	func addBundledUserScript(scriptNameInBundle: String, injectAtStart: Bool = false, injectAtEnd: Bool = false, forMainFrameOnly: Bool = true, sourceReplacements: [String:String]? = nil) {
		assert(injectAtStart || injectAtEnd, "User script must either be injected at start or at end. Add injectAtStart: true or injectAtEnd: true")
		
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
			self.addUserScript(script)
		}
		
		if injectAtEnd {
			let script = WKUserScript(source: scriptSource as String, injectionTime: .AtDocumentEnd, forMainFrameOnly: forMainFrameOnly)
			self.addUserScript(script)
		}
	}
}
