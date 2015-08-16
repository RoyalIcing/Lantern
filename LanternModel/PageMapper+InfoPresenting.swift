//
//  PageMapper+InfoPresenting.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono


extension NSURL {
	var burnt_pathWithQuery: String? {
		if let path = path {
			if let query = query {
				return "\(path)?\(query)"
			}
			else {
				return path
			}
		}
		
		return nil
	}
}


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
	case internalLinks = "internalLinks"
	case externalLinkCount = "externalLinkCount"
	case externalLinks = "externalLinks"
	
	public var longerFormInformation: PagePresentedInfoIdentifier? {
		switch self {
		case .internalLinkCount:
			return .internalLinks
		case .externalLinkCount:
			return .externalLinks
		default:
			return nil
		}
	}
	
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
		case .internalLinkCount, .internalLinks:
			return "Internal Links"
		case .externalLinkCount, .externalLinks:
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
	
	public func validatedStringValueForPendingURL(requestedURL: NSURL) -> ValidatedStringValue {
		switch self {
		case .requestedURL:
			#if DEBUG && false
				return ValidatedStringValue(string: "\(requestedURL)")
			#endif
			
			if let requestedPath = requestedURL.burnt_pathWithQuery {
				return ValidatedStringValue(string: requestedPath)
			}
		default:
			break
		}
		
		return .Missing
	}
	
	public func validatedStringValueInPageInfo(pageInfo: PageInfo, pageMapper: PageMapper) -> ValidatedStringValue {
		switch self {
		case .requestedURL:
			let requestedURL = pageInfo.requestedURL
			if let requestedPath = pageInfo.requestedURL.burnt_pathWithQuery {
				if
					let finalURL = pageInfo.finalURL,
					let finalURLPath = finalURL.burnt_pathWithQuery where requestedURL.absoluteString != finalURL.absoluteString
				{
					if let redirectionInfo = pageMapper.redirectedDestinationURLToInfo[finalURL] {
						return ValidatedStringValue(string: "\(requestedPath) (\(finalURLPath))")
					}
					
					if
						let requestedScheme = requestedURL.scheme,
						let finalScheme = finalURL.scheme
					{
						if requestedScheme != finalScheme {
							return ValidatedStringValue(string: "\(requestedPath) (\(finalURLPath) to \(finalScheme))")
						}
					}
						
					return ValidatedStringValue(string: "\(requestedPath) (\(finalURLPath))")
				}
				
				#if DEBUG && false
					return ValidatedStringValue(string: "\(requestedURL) \(pageInfo.finalURL)")
				#endif
				
				return ValidatedStringValue(string: requestedPath)
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
			if let byteCount = pageInfo.byteCount {
				return ValidatedStringValue(
					string: PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(byteCount))
				)
			}
			else {
				return .NotRequested
			}
		case .pageByteCountBeforeBodyTag:
			if let byteCountBeforeBody = pageInfo.contentInfo?.preBodyByteCount {
				return ValidatedStringValue(
					string: PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(byteCountBeforeBody))
				)
			}
		case .pageByteCountAfterBodyTag:
			if let
				byteCount = pageInfo.byteCount,
				byteCountBeforeBody = pageInfo.contentInfo?.preBodyByteCount
			{
				return ValidatedStringValue(
					string: PagePresentedInfoIdentifier.byteFormatter.stringFromByteCount(Int64(byteCount - byteCountBeforeBody))
				)
			}
		case .internalLinkCount:
			if let localPageURLs = pageInfo.contentInfo?.localPageURLs {
				return ValidatedStringValue(
					string: String(localPageURLs.count)
				)
			}
		case .internalLinks:
			if let localPageURLs = pageInfo.contentInfo?.localPageURLs {
				return ValidatedStringValue.Multiple(
					localPageURLs.map { URL in
						ValidatedStringValue(
							string: URL.absoluteString
						)
					}
				)
			}
		case .externalLinkCount:
			if let externalPageURLs = pageInfo.contentInfo?.externalPageURLs {
				return ValidatedStringValue(
					string: String(externalPageURLs.count)
				)
			}
		case .externalLinks:
			if let externalPageURLs = pageInfo.contentInfo?.externalPageURLs {
				return ValidatedStringValue.Multiple(
					externalPageURLs.map { URL in
						ValidatedStringValue(
							string: URL.absoluteString
						)
					}
				)
			}
		}
		
		return .Missing
	}
}