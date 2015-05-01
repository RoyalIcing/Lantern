//
//  NSData+ONOXMLDocument.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 29/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono


extension NSData {
	func stringRepresentationUsingONOXMLDocumentHints(document: ONOXMLDocument) -> String? {
		var stringEncoding = document.stringEncodingWithFallback()
		return NSString(data: self, encoding: stringEncoding) as? String
	}
}