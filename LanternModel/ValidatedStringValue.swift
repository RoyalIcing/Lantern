//
//	ElementConvenience.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 28/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono



public enum ValidatedStringValue {
	case validString(string: String)
	case missing
	case empty
	case notRequested
	case multiple([ValidatedStringValue])
	case invalid
	
	init(string: String?) {
		if let string = string {
			if string == "" {
				self = .empty
			}
			else {
				self = .validString(string: string)
			}
		}
		else {
			self = .missing
		}
	}
}

private let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines

extension ValidatedStringValue {
	init(string: String, trimmingSpace: Bool, combineSpaces: Bool = false) {
		var string = string
		if combineSpaces {
			string = string.replacingOccurrences(of: "[\\s]+", with: " ", options: .regularExpression, range: nil)
		}
		// Trim whitespace from ends
		string = string.trimmingCharacters(in: whitespaceCharacterSet)
		
		self.init(string: string)
	}
}
	
extension ValidatedStringValue {
	static func validateContentOfElement(_ element: ONOXMLElement) -> ValidatedStringValue {
		let stringValue = element.stringValue()
		
		return self.init(string: stringValue!, trimmingSpace: true, combineSpaces: true)
	}
	
	static func validateContentOfElements(_ elements: [ONOXMLElement]) -> ValidatedStringValue {
		switch elements.count {
		case 1:
			let element = elements[0]
			return validateContentOfElement(element)
		case 0:
			return .missing
		default:
			return .multiple(elements.map { element in
				return self.validateContentOfElement(element)
			})
		}
	}
	
	static func validateAttribute(_ attribute: String, ofElement element: ONOXMLElement) -> ValidatedStringValue {
		if let stringValue = element[attribute] as? String {
			return self.init(string: stringValue, trimmingSpace: true)
		}
		else {
			return .missing
		}
	}
	
	static func validateAttribute(_ attribute: String, ofElements elements: [ONOXMLElement]) -> ValidatedStringValue {
		switch elements.count {
		case 1:
			let element = elements[0]
			return validateAttribute(attribute, ofElement: element)
		case 0:
			return .missing
		default:
			let values: [ValidatedStringValue] = elements.map { element in
				return self.validateAttribute(attribute, ofElement: element)
			}
			return .multiple(values)
		}
	}
}
