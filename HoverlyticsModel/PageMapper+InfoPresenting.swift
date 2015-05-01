//
//  PageMapper+InfoPresenting.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono


public enum PagePresentedInfoIdentifier: String {
	case requestedURL = "requestedURL"
	case statusCode = "statusCode"
	case MIMEType = "MIMEType"
	case pageTitle = "pageTitle"
	case h1 = "h1"
	case metaDescription = "metaDescription"
	case pageByteCount = "pageByteCount"
	case pageByteCountBeforeBodyTag = "pageBeforeBodyTagBytes"
	case pageByteCountAfterBodyTag = "pageAfterBodyTagBytes"
	case internalLinkCount = "internalLinkCount"
	case externalLinkCount = "externalLinkCount"
	
	public func titleForBaseContentType(baseContentType: BaseContentType?) -> String {
		switch self {
		case .requestedURL:
			if let baseContentType = baseContentType {
				switch baseContentType {
				case .LocalHTMLPage:
					return "Page URL"
				case .Image:
					return "Image URL"
				case .Feed:
					return "Feed URL"
				default:
					break
				}
			}
			
			return "URL"
		case .statusCode:
			return "Status Code"
		case .MIMEType:
			return "MIME Type"
		case .pageTitle:
			return "Title"
		case .h1:
			return "H1"
		case .metaDescription:
			return "Meta Description"
		case .pageByteCount:
			return "Total Bytes"
		case .pageByteCountBeforeBodyTag:
			return "<head> Bytes"
		case .pageByteCountAfterBodyTag:
			return "<body> Bytes"
		case .internalLinkCount:
			return "Internal Links"
		case .externalLinkCount:
			return "External Links"
		}
	}
	
	private func stringValueForMultipleElementsContent(elements: [ONOXMLElement]) -> String? {
		switch elements.count {
		case 1:
			let element = elements[0]
			var stringValue = element.stringValue()
			// Conforms spaces and new lines into single spaces
			stringValue = stringValue.stringByReplacingOccurrencesOfString("[\\s]+", withString: " ", options: .RegularExpressionSearch, range: nil)
			// Trim whitespace from ends
			let whitespaceCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
			stringValue = stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
			return stringValue
		case 0:
			return nil
		default:
			return "(multiple)"
		}
	}
	
	private func stringValueForMultipleElements(elements: [ONOXMLElement], attribute: String) -> String? {
		switch elements.count {
		case 1:
			let element = elements[0]
			if let stringValue = element[attribute] as? String {
				return stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
			}
			else {
				return nil
			}
		case 0:
			return nil
		default:
			return "(multiple)"
		}
	}
	
	private static var byteFormatter: NSByteCountFormatter = {
		let byteFormatter = NSByteCountFormatter()
		byteFormatter.countStyle = .Binary
		byteFormatter.adaptive = false
		return byteFormatter
		}()
	
	public func stringValueInPageInfo(pageInfo: PageInfo) -> String? {
		switch self {
		case .requestedURL:
			return pageInfo.requestedURL.relativePath
			//return pageInfo.requestedURL.absoluteString
		case .statusCode:
			return String(pageInfo.statusCode)
		case .MIMEType:
			return pageInfo.MIMEType?.stringValue
		case .pageTitle:
			return stringValueForMultipleElementsContent(pageInfo.contentInfo.pageTitleElements)
		case .h1:
			return stringValueForMultipleElementsContent(pageInfo.contentInfo.h1Elements)
		case .metaDescription:
			return stringValueForMultipleElements(pageInfo.contentInfo.metaDescriptionElements, attribute: "content")
		case .pageByteCount:
			return PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(pageInfo.bytes))
		case .pageByteCountBeforeBodyTag:
			if let byteCountBeforeBody = pageInfo.contentInfo.preBodyByteCount {
				return PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(byteCountBeforeBody))
			}
		case .pageByteCountAfterBodyTag:
			if let byteCountBeforeBody = pageInfo.contentInfo.preBodyByteCount {
				return PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(pageInfo.bytes - byteCountBeforeBody))
			}
		case .internalLinkCount:
			return String(pageInfo.contentInfo.localPageURLs.count)
		case .externalLinkCount:
			return String(pageInfo.contentInfo.externalURLs.count)
		}
		
		return nil
	}
	
	public func validatedStringValueInPageInfo(pageInfo: PageInfo) -> ValidatedStringValue {
		switch self {
		case .requestedURL:
			if let relativePath = pageInfo.requestedURL.relativePath {
				return ValidatedStringValue(string: relativePath)
			}
		case .statusCode:
			return ValidatedStringValue(string: String(pageInfo.statusCode))
		case .MIMEType:
			if let MIMEType = pageInfo.MIMEType?.stringValue {
				return ValidatedStringValue(
					string: MIMEType
				)
			}
		case .pageTitle:
			return ValidatedStringValue.validateContentOfElements(pageInfo.contentInfo.pageTitleElements)
		case .h1:
			return ValidatedStringValue.validateContentOfElements(pageInfo.contentInfo.h1Elements)
		case .metaDescription:
			return ValidatedStringValue.validateAttribute("content", ofElements: pageInfo.contentInfo.metaDescriptionElements)
		case .pageByteCount:
			return ValidatedStringValue(
				string: PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(pageInfo.bytes))
			)
		case .pageByteCountBeforeBodyTag:
			if let byteCountBeforeBody = pageInfo.contentInfo.preBodyByteCount {
				return ValidatedStringValue(
					string: PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(byteCountBeforeBody))
				)
			}
		case .pageByteCountAfterBodyTag:
			if let byteCountBeforeBody = pageInfo.contentInfo.preBodyByteCount {
				return ValidatedStringValue(
					string: PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(pageInfo.bytes - byteCountBeforeBody))
				)
			}
		case .internalLinkCount:
			return ValidatedStringValue(
				string: String(pageInfo.contentInfo.localPageURLs.count)
			)
		case .externalLinkCount:
			return ValidatedStringValue(
				string: String(pageInfo.contentInfo.externalURLs.count)
			)
		}
		
		return .Missing
	}
}