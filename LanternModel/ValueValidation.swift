//
//	ValueValidation.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 31/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


private let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines

public enum ValidationError: Error {
	case stringIsEmpty(string: String, identifier: String)
	
	case urlStringIsInvalid(string: String, identifier: String)
	
	static let errorDomain = "LanternModel.ValueValidation.errorDomain"
	
	fileprivate enum ErrorCode: Int {
		case stringIsEmpty = 10
		
		case urlStringIsInvalid = 20
	}

	
	var errorCode: Int {
		switch self {
		case .stringIsEmpty:
			return ErrorCode.stringIsEmpty.rawValue
		case .urlStringIsInvalid:
			return ErrorCode.urlStringIsInvalid.rawValue
		}
	}
	
	var description: String {
		switch self {
		case .stringIsEmpty(_, let identifier):
			return "Please enter something for \"\(identifier)\""
		case .urlStringIsInvalid(_, let identifier):
			return "Please enter a valid URL for \"\(identifier)\""
		}
	}
	
	var cocoaError: NSError {
		let userInfo = [
			NSLocalizedDescriptionKey: self.description
		]
		return NSError(domain: ValidationError.errorDomain, code: self.errorCode, userInfo: userInfo)
	}
	
	public static func validateString(_ string: String, identifier: String) throws -> String {
		let string = string.trimmingCharacters(in: whitespaceCharacterSet)
		if string.isEmpty {
			throw self.stringIsEmpty(string: string, identifier: identifier).cocoaError
		}
		
		return string
	}
	
	public static func validateURLString(_ URLString: String, identifier: String) throws -> URL {
		do {
			guard let URL = detectWebURL(fromString: URLString) else {
				throw self.urlStringIsInvalid(string: URLString, identifier: identifier).cocoaError
			}
			
			return URL
		}
		catch {
			throw self.urlStringIsInvalid(string: URLString, identifier: identifier).cocoaError
		}
	}
}


public func detectWebURL(fromString URLString: String) -> URL? {
	let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
	
	if let result = dataDetector?.firstMatch(in: URLString, options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, (URLString as NSString).length)) {
		return result.url
	}
	else {
		return nil
	}
}
