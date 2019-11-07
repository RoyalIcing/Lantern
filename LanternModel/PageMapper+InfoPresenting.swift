//
//	PageMapper+InfoPresenting.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 28/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono


extension URL {
	var burnt_pathWithQuery: String {
		if let query = query {
			return "\(path)?\(query)"
		}
		else {
			return path
		}
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
	
	public func titleForBaseContentType(_ baseContentType: BaseContentType?) -> String {
		switch self {
		case .requestedURL:
			if let baseContentType = baseContentType {
				switch baseContentType {
				case .localHTMLPage:
					return "Path"
				case .image:
					return "Image URL"
				case .feed:
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
	
	fileprivate func stringValueForMultipleElementsContent(_ elements: [ONOXMLElement]) -> String? {
		switch elements.count {
		case 1:
			let element = elements[0]
			var stringValue = element.stringValue() ?? ""
			// Conforms spaces and new lines into single spaces
			stringValue = stringValue.replacingOccurrences(of: "[\\s]+", with: " ", options: .regularExpression, range: nil)
			// Trim whitespace from ends
			stringValue = stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
			return stringValue
		case 0:
			return nil
		default:
			return "(multiple)"
		}
	}
	
	fileprivate func stringValueForMultipleElements(_ elements: [ONOXMLElement], attribute: String) -> String? {
		switch elements.count {
		case 1:
			let element = elements[0]
			if let stringValue = element[attribute] as? String {
				return stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
	
	fileprivate static var byteFormatter: ByteCountFormatter = {
		let byteFormatter = ByteCountFormatter()
		byteFormatter.countStyle = .binary
		byteFormatter.isAdaptive = false
		return byteFormatter
	}()
	
	public func validatedStringValueForPendingURL(_ requestedURL: URL) -> ValidatedStringValue {
		switch self {
		case .requestedURL:
			#if DEBUG && false
				return ValidatedStringValue(string: "\(requestedURL)")
			#endif
			
			return ValidatedStringValue(string: requestedURL.burnt_pathWithQuery)
		default:
			break
		}
		
		return .missing
	}
	
	public func validatedStringValueInPageInfo(_ pageInfo: PageInfo, pageMapper: PageMapper) -> ValidatedStringValue {
		switch self {
		case .requestedURL:
			let requestedURL = pageInfo.requestedURL
			let requestedPath = requestedURL.burnt_pathWithQuery
			if
				let finalURL = pageInfo.finalURL,
				requestedURL.absoluteString != finalURL.absoluteString
			{
				let finalURLPath = finalURL.burnt_pathWithQuery
				if pageMapper.redirectedDestinationURLToInfo[finalURL] != nil {
					return ValidatedStringValue(string: "\(requestedPath) (\(finalURLPath))")
				}
				
				let requestedScheme = requestedURL.scheme
				let finalScheme = finalURL.scheme
				if requestedScheme != finalScheme {
					return ValidatedStringValue(string: "\(requestedPath) (\(finalURLPath) to \(String(describing: finalScheme)))")
				}
					
				return ValidatedStringValue(string: "\(requestedPath) (\(finalURLPath))")
			}
			
			#if DEBUG && false
				return ValidatedStringValue(string: "\(requestedURL) \(pageInfo.finalURL)")
			#endif
			
			return ValidatedStringValue(string: requestedPath)
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
					string: PagePresentedInfoIdentifier.byteFormatter.string(fromByteCount: Int64(byteCount))
				)
			}
			else {
				return .notRequested
			}
		case .pageByteCountBeforeBodyTag:
			if let byteCountBeforeBody = pageInfo.contentInfo?.preBodyByteCount {
				return ValidatedStringValue(
					string: PagePresentedInfoIdentifier.byteFormatter.string(fromByteCount: Int64(byteCountBeforeBody))
				)
			}
		case .pageByteCountAfterBodyTag:
			if let
				byteCount = pageInfo.byteCount,
				let byteCountBeforeBody = pageInfo.contentInfo?.preBodyByteCount
			{
				return ValidatedStringValue(
					string: PagePresentedInfoIdentifier.byteFormatter.string(fromByteCount: Int64(byteCount - byteCountBeforeBody))
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
				return ValidatedStringValue.multiple(
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
				return ValidatedStringValue.multiple(
					externalPageURLs.map { URL in
						ValidatedStringValue(
							string: URL.absoluteString
						)
					}
				)
			}
		}
		
		return .missing
	}
}
