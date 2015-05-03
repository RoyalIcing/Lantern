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
	
	public func validatedStringValueInPageInfo(pageInfo: PageInfo) -> ValidatedStringValue {
		switch self {
		case .requestedURL:
			if let relativePath = pageInfo.requestedURL.relativePath {
				if let finalURLPath = pageInfo.finalURL?.relativePath where pageInfo.requestedURL.absoluteURL != pageInfo.finalURL?.absoluteURL {
					return ValidatedStringValue(string: "\(relativePath) (\(finalURLPath))")
				}
				else {
					return ValidatedStringValue(string: relativePath)
				}
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
			if let pageTitleElements = pageInfo.contentInfo?.pageTitleElements {
				return ValidatedStringValue.validateContentOfElements(pageTitleElements)
			}
		case .h1:
			if let h1Elements = pageInfo.contentInfo?.h1Elements {
				return ValidatedStringValue.validateContentOfElements(h1Elements)
			}
		case .metaDescription:
			if let metaDescriptionElements = pageInfo.contentInfo?.metaDescriptionElements {
				return ValidatedStringValue.validateAttribute("content", ofElements: metaDescriptionElements)
			}
		case .pageByteCount:
			return ValidatedStringValue(
				string: PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(pageInfo.bytes))
			)
		case .pageByteCountBeforeBodyTag:
			if let byteCountBeforeBody = pageInfo.contentInfo?.preBodyByteCount {
				return ValidatedStringValue(
					string: PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(byteCountBeforeBody))
				)
			}
		case .pageByteCountAfterBodyTag:
			if let byteCountBeforeBody = pageInfo.contentInfo?.preBodyByteCount {
				return ValidatedStringValue(
					string: PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(pageInfo.bytes - byteCountBeforeBody))
				)
			}
		case .internalLinkCount:
			if let localPageURLs = pageInfo.contentInfo?.localPageURLs {
				return ValidatedStringValue(
					string: String(localPageURLs.count)
				)
			}
		case .externalLinkCount:
			if let externalURLs = pageInfo.contentInfo?.externalURLs {
				return ValidatedStringValue(
					string: String(externalURLs.count)
				)
			}
		}
		
		return .Missing
	}
}