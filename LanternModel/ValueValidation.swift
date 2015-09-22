//
//  ValueValidation.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 31/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


private let whitespaceCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

public enum ValidationError: ErrorType {
	case StringIsEmpty(string: String, identifier: String)
	
	case URLStringIsInvalid(string: String, identifier: String)
	
	static let errorDomain = "LanternModel.ValueValidation.errorDomain"
	
	private enum ErrorCode: Int {
		case StringIsEmpty = 10
		
		case URLStringIsInvalid = 20
	}

	
	var errorCode: Int {
		switch self {
		case StringIsEmpty:
			return ErrorCode.StringIsEmpty.rawValue
		case URLStringIsInvalid:
			return ErrorCode.URLStringIsInvalid.rawValue
		}
	}
	
	var description: String {
		switch self {
		case StringIsEmpty(_, let identifier):
			return "Please enter something for \"\(identifier)\""
		case URLStringIsInvalid(_, let identifier):
			return "Please enter a valid URL for \"\(identifier)\""
		}
	}
	
	var cocoaError: NSError {
		let userInfo = [
			NSLocalizedDescriptionKey: self.description
		]
		return NSError(domain: ValidationError.errorDomain, code: self.errorCode, userInfo: userInfo)
	}
	
	public static func validateString(string: String, identifier: String) throws -> String {
		let string = string.stringByTrimmingCharactersInSet(whitespaceCharacterSet)
		if string.isEmpty {
			throw self.StringIsEmpty(string: string, identifier: identifier).cocoaError
		}
		
		return string
	}
	
	public static func validateURLString(URLString: String, identifier: String) throws -> NSURL {
		do {
			guard let URL = detectWebURL(fromString: URLString) else {
				throw self.URLStringIsInvalid(string: URLString, identifier: identifier).cocoaError
			}
			
			return URL
		}
		catch {
			throw self.URLStringIsInvalid(string: URLString, identifier: identifier).cocoaError
		}
	}
}


public func detectWebURL(fromString URLString: String) -> NSURL? {
	let dataDetector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue)
	
	if let result = dataDetector?.firstMatchInString(URLString, options: NSMatchingOptions(), range: NSMakeRange(0, (URLString as NSString).length)) {
		return result.URL
	}
	else {
		return nil
	}
}
