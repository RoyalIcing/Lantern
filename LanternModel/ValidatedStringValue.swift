//
//  ElementConvenience.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono



public enum ValidatedStringValue {
	case ValidString(string: String)
	case Missing
	case Empty
	case NotRequested
	case Multiple([ValidatedStringValue])
	case Invalid
	
	init(string: String?) {
		if let string = string {
			if string == "" {
				self = .Empty
			}
			else {
				self = .ValidString(string: string)
			}
		}
		else {
			self = .Missing
		}
	}
}

private let whitespaceCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

extension ValidatedStringValue {
	init(var string: String, trimmingSpace: Bool, combineSpaces: Bool = false) {
		if combineSpaces {
			string = string.stringByReplacingOccurrencesOfString("[\\s]+", withString: " ", options: .RegularExpressionSearch, range: nil)
		}
		// Trim whitespace from ends
		string = string.stringByTrimmingCharactersInSet(whitespaceCharacterSet)
		
		self.init(string: string)
	}
	
	static func validateContentOfElement(element: ONOXMLElement) -> ValidatedStringValue {
		var stringValue = element.stringValue()
		
		return self.init(string: stringValue, trimmingSpace: true, combineSpaces: true)
	}
	
	static func validateContentOfElements(elements: [ONOXMLElement]) -> ValidatedStringValue {
		switch elements.count {
		case 1:
			let element = elements[0]
			return validateContentOfElement(element)
		case 0:
			return .Missing
		default:
			return .Multiple(elements.map { element in
				return self.validateContentOfElement(element)
			})
		}
	}
	
	static func validateAttribute(attribute: String, ofElement element: ONOXMLElement) -> ValidatedStringValue {
		if let stringValue = element[attribute] as? String {
			return self.init(string: stringValue, trimmingSpace: true)
		}
		else {
			return .Missing
		}
	}
	
	static func validateAttribute(attribute: String, ofElements elements: [ONOXMLElement]) -> ValidatedStringValue {
		switch elements.count {
		case 1:
			let element = elements[0]
			return validateAttribute(attribute, ofElement: element)
		case 0:
			return .Missing
		default:
			var values: [ValidatedStringValue] = elements.map { element in
				return self.validateAttribute(attribute, ofElement: element)
			}
			return .Multiple(values)
		}
	}
}
