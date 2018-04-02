//
//	NSData+ONOXMLDocument.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 29/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono


extension Data {
	func stringRepresentationUsingONOXMLDocumentHints(_ document: ONOXMLDocument) -> String? {
		let stringEncoding = document.stringEncodingWithFallback()
		return NSString(data: self, encoding: stringEncoding.rawValue) as String?
	}
}
