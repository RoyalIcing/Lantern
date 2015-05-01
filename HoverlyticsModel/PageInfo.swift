//
//  PageInfo.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Alamofire
import Ono


public enum BaseContentType {
	case Unknown
	case LocalHTMLPage
	case Text
	case Image
	case Feed
}

extension BaseContentType: DebugPrintable {
	 public var debugDescription: String {
		switch self {
		case .Unknown:
			return "Unknown"
		case .LocalHTMLPage:
			return "LocalHTMLPage"
		case .Text:
			return "Text"
		case .Image:
			return "Image"
		case .Feed:
			return "Feed"
		}
	}
}


private typealias ONOXMLElementFilter = (element: ONOXMLElement) -> Bool

extension ONOXMLDocument {
	private func allElementsWithCSS(selector: String, filter: ONOXMLElementFilter? = nil) -> [ONOXMLElement] {
		var elements = [ONOXMLElement]()
		self.enumerateElementsWithCSS(selector) { (element, index, stop) in
			if filter?(element: element) == false {
				return
			}
			elements.append(element)
		}
		return elements
	}
}



public enum PageResponseType: Int {
	case Successful = 2
	case Redirects = 3
	case RequestErrors = 4
	case ResponseErrors = 5
	case Unknown = 0
}

extension PageResponseType {
	init(statusCode: Int) {
		switch statusCode {
		case 200..<300:
			self = .Successful
		case 300..<400:
			self = .Redirects
		case 400..<500:
			self = .RequestErrors
		case 500..<600:
			self = .ResponseErrors
		default:
			self = .Unknown
		}
	}
}



private func URLIsExternal(URLToTest: NSURL, #localHost: String) -> Bool {
	if let host = URLToTest.host {
		if host.caseInsensitiveCompare(localHost) != .OrderedSame {
			return true
		}
	}
	
	return false
}



public struct MIMETypeString {
	public let stringValue: String
	
	init?(_ stringValue: String?) {
		if let stringValue = stringValue {
			self.stringValue = stringValue
		}
		else {
			return nil
		}
	}
	
	var isHTML: Bool {
		return stringValue == "text/html"
	}
	
	var isText: Bool {
		return stringValue.hasPrefix("text/")
	}
	
	var isImage: Bool {
		return stringValue.hasPrefix("image/")
	}
	
	private static let feedTypes = Set<String>(["application/rss+xml", "application/rdf+xml", "application/atom+xml", "application/xml", "text/xml"])
	
	var isFeed: Bool {
		let feedTypes = MIMETypeString.feedTypes
		return feedTypes.contains(stringValue)
	}
	
	var baseContentType: BaseContentType {
		if isHTML {
			return .LocalHTMLPage
		}
		else if isText {
			return .Text
		}
		else if isImage {
			return .Image
		}
		else if isFeed {
			return .Feed
		}
		else {
			return .Unknown
		}
	}
}

extension MIMETypeString: Printable {
	public var description: String {
		return stringValue
	}
}




struct PageContentInfoOptions {
	var separateLinksToImageTypes = true
}

public struct PageContentInfo {
	public let data: NSData
	public let document: ONOXMLDocument
	
	public let preBodyByteCount: Int?
	
	public let pageTitleElements: [ONOXMLElement]
	
	public let metaDescriptionElements: [ONOXMLElement]
	public let openGraphElements: [ONOXMLElement]
	
	private let uniqueFeedURLs: UniqueURLArray
	public var feedURLs: [NSURL] {
		return uniqueFeedURLs.orderedURLs
	}
	public let feedLinkElements: [ONOXMLElement]
	
	public let externalURLs: Set<NSURL>
	public let aExternalLinkElements: [ONOXMLElement]
	
	private let uniqueLocalPageURLs: UniqueURLArray
	public var localPageURLs: [NSURL] {
		return uniqueLocalPageURLs.orderedURLs
	}
	public let aLocalLinkElements: [ONOXMLElement]
	
	public let imageURLs: Set<NSURL>
	public let imageElements: [ONOXMLElement]
	
	//public let stylesheetURLs: Set<NSURL>
	//public let stylesheetElements: [ONOXMLElement]
	
	public let h1Elements: [ONOXMLElement]
	public let richSnippetElements: [ONOXMLElement]
	
	private init(data: NSData, localURL: NSURL, options: PageContentInfoOptions = PageContentInfoOptions()) {
		self.data = data
		
		var error: NSError?
		let document = ONOXMLDocument.HTMLDocumentWithData(data, error: &error)
		
		self.document = document
		
		let stringEncoding = document.stringEncodingWithFallback()
		if let bodyTagData = "<body".dataUsingEncoding(stringEncoding, allowLossyConversion: false) {
			let bodyTagRange = data.rangeOfData(bodyTagData, options: .allZeros, range: NSMakeRange(0, data.length))
			if bodyTagRange.location != NSNotFound {
				preBodyByteCount = bodyTagRange.location
			}
			else {
				preBodyByteCount = nil
			}
		}
		else {
			preBodyByteCount = nil
		}
		
		pageTitleElements = document.allElementsWithCSS("head title")
		
		metaDescriptionElements = document.allElementsWithCSS("head meta[name][content]") { element in
			if let name = element["name"] as? String {
				return name.caseInsensitiveCompare("description") == .OrderedSame
			}
			
			return false
		}
		openGraphElements = document.allElementsWithCSS("head meta[property]") { element in
			if let name = element["property"] as? String {
				return name.rangeOfString("og:", options: .AnchoredSearch | .CaseInsensitiveSearch) != nil
			}
			
			return false
		}
		
		var uniqueFeedURLs = UniqueURLArray()
		feedLinkElements = document.allElementsWithCSS("head link[type][href]") { element in
			if
				let typeRaw = element["type"] as? String,
				let MIMEType = MIMETypeString(typeRaw.lowercaseString),
				let linkURLString = element["href"] as? String,
				let linkURL = NSURL(string: linkURLString, relativeToURL: localURL)
			{
				if MIMEType.isFeed {
					uniqueFeedURLs.insertReturningConformedURLIfNew(linkURL)
					return true
				}
			}
			
			return false
		}
		self.uniqueFeedURLs = uniqueFeedURLs
		
		
		let localHost = localURL.host!
		let separateLinksToImageTypes = options.separateLinksToImageTypes
		
		var aLocalLinkElements = [ONOXMLElement]()
		var aExternalLinkElements = [ONOXMLElement]()
		var uniqueLocalPageURLs = UniqueURLArray()
		var externalURLs = Set<NSURL>()
		
		var imageElements = [ONOXMLElement]()
		var imageURLs = Set<NSURL>()
		
		document.enumerateElementsWithCSS("a[href]") { (aLinkElement, index, stop) in
			if
				let linkURLString = aLinkElement["href"] as? String,
				let linkURL = NSURL(string: linkURLString, relativeToURL: localURL)
			{
				if separateLinksToImageTypes {
					let hasImageType = [".jpg", ".jpeg", ".png", ".gif"].reduce(false, combine: { (hasSoFar, suffix) -> Bool in
						return hasSoFar || linkURLString.hasSuffix(suffix)
					})
					
					if hasImageType {
						imageElements.append(aLinkElement)
						imageURLs.insert(linkURL)
						return
					}
				}
				
				let isExternal = URLIsExternal(linkURL, localHost: localHost)
				
				if isExternal {
					aExternalLinkElements.append(aLinkElement)
					externalURLs.insert(linkURL)
				}
				else {
					aLocalLinkElements.append(aLinkElement)
					uniqueLocalPageURLs.insertReturningConformedURLIfNew(linkURL)
				}
			}
		}
		self.aLocalLinkElements = aLocalLinkElements
		self.aExternalLinkElements = aExternalLinkElements
		self.uniqueLocalPageURLs = uniqueLocalPageURLs
		self.externalURLs = externalURLs
		
		document.enumerateElementsWithCSS("img[src]") { (imgElement, index, stop) in
			if
				let imageURLString = imgElement["src"] as? String,
				let imageURL = NSURL(string: imageURLString, relativeToURL: localURL)
			{
				//let isExternal = URLIsExternal(linkURL, localHost: localHost)
				
				imageElements.append(imgElement)
				imageURLs.insert(imageURL)
			}
		}
		self.imageElements = imageElements
		self.imageURLs = imageURLs
		
		h1Elements = document.allElementsWithCSS("h1")
		
		richSnippetElements = [] //TODO:
	}
	
	public var HTMLHeadData: NSData? {
		if let preBodyByteCount = preBodyByteCount {
			return data.subdataWithRange(NSMakeRange(0, preBodyByteCount))
		}
		
		return nil
	}
	
	public var HTMLBodyData: NSData? {
		if let preBodyByteCount = preBodyByteCount {
			return data.subdataWithRange(NSMakeRange(preBodyByteCount, data.length - preBodyByteCount))
		}
		
		return nil
	}
	
	public var stringContent: String? {
		return data.stringRepresentationUsingONOXMLDocumentHints(document)
	}
	
	public var HTMLHeadStringContent: String? {
		return HTMLHeadData?.stringRepresentationUsingONOXMLDocumentHints(document)
	}
	
	public var HTMLBodyStringContent: String? {
		return HTMLBodyData?.stringRepresentationUsingONOXMLDocumentHints(document)
	}
}


public struct PageInfo {
	public let requestedURL: NSURL
	public let finalURL: NSURL?
	public let statusCode: Int
	public let baseContentType: BaseContentType
	public let MIMEType: MIMETypeString?
	public let bytes: Int
	
	public let contentInfo: PageContentInfo!
	
	static func retrieveInfoForPageWithURL(pageURL: NSURL, completionHandler: (pageInfo: PageInfo) -> Void) {
		Alamofire
			.request(.GET, pageURL)
			.response { (request, response, data, error) in
				if
					let response = response,
					let data = data as? NSData
				{
					let MIMEType = MIMETypeString(response.MIMEType)
					let baseContentType: BaseContentType = MIMEType?.baseContentType ?? .Unknown
					
					let contentInfo = PageContentInfo(data: data, localURL: pageURL)
					
					var pageInfo = PageInfo(requestedURL: pageURL, finalURL: response.URL, statusCode: response.statusCode, baseContentType: baseContentType, MIMEType: MIMEType, bytes: data.length, contentInfo: contentInfo)
					
					completionHandler(pageInfo: pageInfo)
				}
		}
	}
}
