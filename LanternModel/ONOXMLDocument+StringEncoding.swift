//
//	ONOXMLDocument+StringEncoding.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 29/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono


extension ONOXMLDocument {
	func stringEncodingWithFallback(_ fallback: String.Encoding = String.Encoding.utf8) -> String.Encoding {
		var stringEncoding = self.stringEncoding
		if stringEncoding == 0 {
			stringEncoding = fallback.rawValue
		}
		return String.Encoding(rawValue: stringEncoding)
	}
}
