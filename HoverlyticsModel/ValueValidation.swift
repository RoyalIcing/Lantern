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


private enum Error {
	case StringIsEmpty(string: String)
	
	case URLStringIsInvalid(string: String)
	
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
		case StringIsEmpty:
			return "Please enter"
		case URLStringIsInvalid:
			return "Please enter a valid URL"
		}
	}
	
	var cocoaError: NSError {
		let userInfo = [
			NSLocalizedDescriptionKey: self.description
		]
		return NSError(domain: ValueValidationErrorDomain, code: self.errorCode, userInfo: userInfo)
	}
}


private let whitespaceCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

public enum ValueValidation {
	case InputtedString(String)
	case InputtedURLString(String)
	
	public static func validateString(string: String) -> (string: String?, error: NSError?) {
		let string = string.stringByTrimmingCharactersInSet(whitespaceCharacterSet)
		if string.isEmpty {
			return (nil, Error.StringIsEmpty(string: string).cocoaError)
		}
		
		return (string, nil)
	}
	
	public static func validateURLString(URLString: String) -> (URL: NSURL?, error: NSError?) {
		if let URL = detectWebURL(fromString: URLString) {
			return (URL, nil)
		}
		else {
			return (nil, Error.URLStringIsInvalid(string: URLString).cocoaError)
		}
	}

	private var validateReturningInternalError: Error? {
		var stringToCheck: String?
		var checkStringForURL = false
		
		switch self {
		case .InputtedString(let string):
			stringToCheck = string
		case .InputtedURLString(let URLString):
			stringToCheck = URLString
			checkStringForURL = true
		}
		
		if let string = stringToCheck {
			let string = string.stringByTrimmingCharactersInSet(whitespaceCharacterSet)
			if string.isEmpty {
				return .StringIsEmpty(string: string)
			}
			
			if checkStringForURL {
				if detectWebURL(fromString: string) == nil {
					return .URLStringIsInvalid(string: string)
				}
			}
		}
	
		return nil
	}
	
	public var validateReturningCocoaError: NSError? {
		return validateReturningInternalError?.cocoaError
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
