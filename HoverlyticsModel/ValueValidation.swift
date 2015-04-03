//
//  ValueValidation.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 31/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public let ValueValidationErrorDomain = "HoverlyticsModel.ValueValidation.errorDomain"

public enum ValueValidationErrorCode: Int {
	case StringIsEmpty = 10
	
	case URLStringIsInvalid = 20
}


private let whitespaceCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

public enum ValidationError {
	case StringIsEmpty(string: String, identifier: String)
	
	case URLStringIsInvalid(string: String, identifier: String)
	
	var errorCode: Int {
		switch self {
		case StringIsEmpty:
			return ValueValidationErrorCode.StringIsEmpty.rawValue
		case URLStringIsInvalid:
			return ValueValidationErrorCode.URLStringIsInvalid.rawValue
		}
	}
	
	var description: String {
		switch self {
		case StringIsEmpty(let string, let identifier):
			return "Please enter something for \"\(identifier)\""
		case URLStringIsInvalid(let string, let identifier):
			return "Please enter a valid URL for \"\(identifier)\""
		}
	}
	
	var cocoaError: NSError {
		let userInfo = [
			NSLocalizedDescriptionKey: self.description
		]
		return NSError(domain: ValueValidationErrorDomain, code: self.errorCode, userInfo: userInfo)
	}
	
	public static func validateString(string: String, identifier: String) -> (string: String?, error: NSError?) {
		let string = string.stringByTrimmingCharactersInSet(whitespaceCharacterSet)
		if string.isEmpty {
			return (nil, self.StringIsEmpty(string: string, identifier: identifier).cocoaError)
		}
		
		return (string, nil)
	}
	
	public static func validateURLString(URLString: String, identifier: String) -> (URL: NSURL?, error: NSError?) {
		if let URL = detectWebURL(fromString: URLString) {
			return (URL, nil)
		}
		else {
			return (nil, self.URLStringIsInvalid(string: URLString, identifier: identifier).cocoaError)
		}
	}
}


public func detectWebURL(fromString URLString: String) -> NSURL? {
	var error: NSError?
	let dataDetector = NSDataDetector(types: NSTextCheckingType.Link.rawValue, error: &error)
	
	if let result = dataDetector?.firstMatchInString(URLString, options: NSMatchingOptions.allZeros, range: NSMakeRange(0, (URLString as NSString).length)) {
		return result.URL
	}
	else {
		return nil
	}
}
