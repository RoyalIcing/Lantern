//
//	PageInfoValidationResult.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 28/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono


public enum PageInfoValidationResult {
	case valid
	case notRequested
	case missing
	case empty
	case multiple
	case invalid
}

private let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines
private let nonWhitespaceCharacterSet = whitespaceCharacterSet.inverted

private func stringIsJustWhitespace(_ string: String) -> Bool {
	// Return range if non-whitespace characters are present, nil if no non-whitespace characters are present.
	return string.rangeOfCharacter(from: nonWhitespaceCharacterSet, options: [], range: nil) == nil
}

extension PageInfoValidationResult {
	init(validatedStringValue: ValidatedStringValue) {
		switch validatedStringValue{
		case .validString, .validKeyValue:
			self = .valid
		case .notRequested:
			self = .notRequested
		case .missing:
			self = .missing
		case .empty:
			self = .empty
		case .multiple:
			self = .multiple
		case .invalid:
			self = .invalid
		}
	}
	
	static func validateContentsOfElements(_ elements: [ONOXMLElement]) -> PageInfoValidationResult {
		let validatedStringValue = ValidatedStringValue.validateContentOfElements(elements)
		return self.init(validatedStringValue: validatedStringValue)
	}
	
	static func validateMIMEType(_ MIMEType: String) -> PageInfoValidationResult {
		if stringIsJustWhitespace(MIMEType) {
			return .missing
		}
		
		return .valid
	}
}


public enum PageInfoValidationArea: Int {
	case mimeType = 1
	case Title = 2
	case h1 = 3
	case metaDescription = 4
	
	var title: String {
		switch self {
		case .mimeType:
			return "MIME Type"
		case .Title:
			return "Title"
		case .h1:
			return "H1"
		case .metaDescription:
			return "Meta Description"
		}
	}
	
	var isRequired: Bool {
		return true
	}
	
	static var allAreas = Set<PageInfoValidationArea>([.mimeType, .Title, .h1, .metaDescription])
}

extension PageInfo {
	public func validateArea(_ validationArea: PageInfoValidationArea) -> PageInfoValidationResult {
		switch validationArea {
		case .mimeType:
			if let MIMEType = MIMEType {
				return PageInfoValidationResult.validateMIMEType(MIMEType.stringValue)
			}
		case .Title:
			if let pageTitleElements = contentInfo?.pageTitleElements {
				return PageInfoValidationResult.validateContentsOfElements(pageTitleElements)
			}
		case .h1:
			if let h1Elements = contentInfo?.h1Elements {
				return PageInfoValidationResult.validateContentsOfElements(h1Elements)
			}
		case .metaDescription:
			if let metaDescriptionElements = self.contentInfo?.metaDescriptionElements {
				switch metaDescriptionElements.count {
				case 1:
					let element = metaDescriptionElements[0]
					let validatedStringValue = ValidatedStringValue.validateAttribute("content", ofElement: element)
					return PageInfoValidationResult(validatedStringValue: validatedStringValue)
				case 0:
					return .missing
				default:
					return .multiple
				}
			}
		}
		
		return .missing
	}
}


public extension PageMapper {
	func copyHTMLPageURLsWhichCompletelyValidateForType(_ type: BaseContentType) -> [URL] {
		let validationAreas = PageInfoValidationArea.allAreas
		let URLs = copyURLsWithBaseContentType(type, withResponseType: .successful)
		
		return URLs.filter { URL in
			guard let pageInfo = self.loadedURLToPageInfo[URL] else { return false }
			
			let containsInvalidResult = validationAreas.contains { validationArea in
				return pageInfo.validateArea(validationArea) != .valid
			}
			
			return !containsInvalidResult
		}
	}
	
	func copyHTMLPageURLsForType(_ type: BaseContentType, failingToValidateInArea validationArea: PageInfoValidationArea) -> [URL] {
		let URLs = copyURLsWithBaseContentType(type, withResponseType: .successful)
		
		return URLs.filter { URL in
			guard let pageInfo = self.loadedURLToPageInfo[URL] else { return false }
			
			switch pageInfo.validateArea(validationArea) {
			case .valid:
				return false
			case .missing:
				return validationArea.isRequired // Only invalid if it is required
			default:
				return true
			}
		}
	}
}
