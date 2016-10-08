//
//	PageInfo.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 28/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Alamofire
import Ono


public enum BaseContentType {
	case unknown
	case localHTMLPage
	case text
	case image
	case feed
	case redirect
	case essential
}

extension BaseContentType: CustomDebugStringConvertible {
	 public var debugDescription: String {
		switch self {
		case .unknown:
			return "Unknown"
		case .localHTMLPage:
			return "LocalHTMLPage"
		case .text:
			return "Text"
		case .image:
			return "Image"
		case .feed:
			return "Feed"
		case .redirect:
			return "Redirect"
		case .essential:
			return "Essential"
		}
	}
}


private typealias ONOXMLElementFilter = (_ element: ONOXMLElement) -> Bool

extension ONOXMLDocument {
	fileprivate func allElementsWithCSS(_ selector: String, filter: ONOXMLElementFilter? = nil) -> [ONOXMLElement] {
		var elements = [ONOXMLElement]()
		self.enumerateElements(withCSS: selector) { (element, index, stop) in
			if filter?(element!) == false {
				return
			}
			elements.append(element!)
		}
		return elements
	}
}



public enum PageResponseType: Int {
	case successful = 2
	case redirects = 3
	case requestErrors = 4
	case responseErrors = 5
	case unknown = 0
}

extension PageResponseType {
	public init(statusCode: Int) {
		switch statusCode {
		case 200..<300:
			self = .successful
		case 300..<400:
			self = .redirects
		case 400..<500:
			self = .requestErrors
		case 500..<600:
			self = .responseErrors
		default:
			self = .unknown
		}
	}
}



internal func URLIsExternal(_ URLToTest: URL, localHost: String) -> Bool {
	if let host = URLToTest.host {
		if host.caseInsensitiveCompare(localHost) != .orderedSame {
			return true
		}
	}
	
	return false
}

private let fileDownloadFileExtensions = Set<String>(["zip", "dmg", "exe", "pdf", "gz", "tar", "doc", "docx", "xls", "wav", "aiff", "mp3", "mp4", "mov", "avi", "wmv"])

func linkedURLLooksLikeFileDownload(_ url: URL) -> Bool {
	let pathExtension = url.pathExtension
	if fileDownloadFileExtensions.contains(pathExtension) {
		return true
	}
	
	return false
}



public struct MIMETypeString {
	public let stringValue: String
}

extension MIMETypeString {
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
	
	fileprivate static let feedTypes = Set<String>(["application/rss+xml", "application/rdf+xml", "application/atom+xml", "application/xml", "text/xml"])
	
	var isFeed: Bool {
		let feedTypes = MIMETypeString.feedTypes
		return feedTypes.contains(stringValue)
	}
	
	var baseContentType: BaseContentType {
		if isHTML {
			return .localHTMLPage
		}
		else if isText {
			return .text
		}
		else if isImage {
			return .image
		}
		else if isFeed {
			return .feed
		}
		else {
			return .unknown
		}
	}
}

extension MIMETypeString: CustomStringConvertible {
	public var description: String {
		return stringValue
	}
}




struct PageContentInfoOptions {
	var separateLinksToImageTypes = true
}

public struct PageContentInfo {
	public let data: Data
	fileprivate let document: ONOXMLDocument!
	let stringEncoding: String.Encoding!
	
	public let preBodyByteCount: Int?
	
	public let pageTitleElements: [ONOXMLElement]
	
	public let metaDescriptionElements: [ONOXMLElement]
	public let openGraphElements: [ONOXMLElement]
	
	fileprivate let uniqueFeedURLs: UniqueURLArray
	public var feedURLs: [URL] {
		return uniqueFeedURLs.orderedURLs as [URL]
	}
	public let feedLinkElements: [ONOXMLElement]
	
	fileprivate let uniqueExternalPageURLs: UniqueURLArray
	public var externalPageURLs: [URL] {
		return uniqueExternalPageURLs.orderedURLs as [URL]
	}
	public let aExternalLinkElements: [ONOXMLElement]
	
	fileprivate let uniqueLocalPageURLs: UniqueURLArray
	public var localPageURLs: [URL] {
		return uniqueLocalPageURLs.orderedURLs as [URL]
	}
	public func containsLocalPageURL(_ URL: Foundation.URL) -> Bool {
		return uniqueLocalPageURLs.contains(URL)
	}
	public let aLocalLinkElements: [ONOXMLElement]
	
	public let imageURLs: Set<URL>
	public func containsImageURL(_ URL: Foundation.URL) -> Bool {
		return imageURLs.contains(URL)
	}
	public let imageElements: [ONOXMLElement]
	
	//public let stylesheetURLs: Set<NSURL>
	//public let stylesheetElements: [ONOXMLElement]
	
	public let h1Elements: [ONOXMLElement]
	public let richSnippetElements: [ONOXMLElement]
	
	init(data: Data, localURL: URL, options: PageContentInfoOptions = PageContentInfoOptions()) {
		self.data = data
		
		do {
			let document = try ONOXMLDocument.htmlDocument(with: data)
			self.stringEncoding = document.stringEncodingWithFallback()
			// Must store document to also save references to all found elements.
			self.document = document
			
			let stringEncoding = document.stringEncodingWithFallback()
			if let bodyTagData = "<body".data(using: stringEncoding, allowLossyConversion: false) {
				let bodyTagRange = data.range(of: bodyTagData)
				preBodyByteCount = bodyTagRange?.lowerBound
			}
			else {
				preBodyByteCount = nil
			}
			
			pageTitleElements = document.allElementsWithCSS("head title")
			
			metaDescriptionElements = document.allElementsWithCSS("head meta[name][content]") { element in
				if let name = element["name"] as? String {
					return name.caseInsensitiveCompare("description") == .orderedSame
				}
				
				return false
			}
			openGraphElements = document.allElementsWithCSS("head meta[property]") { element in
				if let name = element["property"] as? String {
					return name.range(of: "og:", options: [.anchored, .caseInsensitive]) != nil
				}
				
				return false
			}
			
			let uniqueFeedURLs = UniqueURLArray()
			feedLinkElements = document.allElementsWithCSS("head link[type][href]") { element in
				if
					let typeRaw = element["type"] as? String,
					let MIMEType = MIMETypeString(typeRaw.lowercased()),
					let linkURLString = element["href"] as? String,
					let linkURL = URL(string: linkURLString, relativeTo: localURL)
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
			let uniqueLocalPageURLs = UniqueURLArray()
			let uniqueExternalPageURLs = UniqueURLArray()
			
			var imageElements = [ONOXMLElement]()
			var imageURLs = Set<URL>()
			
			document.enumerateElements(withCSS: "a[href]") { (aLinkElement, index, stop) in
				if
					let linkURLString = aLinkElement?["href"] as? String,
					let linkURL = URL(string: linkURLString, relativeTo: localURL)
				{
					if separateLinksToImageTypes {
						let hasImageType = [".jpg", ".jpeg", ".png", ".gif"].reduce(false, { (hasSoFar, suffix) -> Bool in
							return hasSoFar || linkURLString.hasSuffix(suffix)
						})
						
						if hasImageType {
							imageElements.append(aLinkElement!)
							imageURLs.insert(linkURL)
							return
						}
					}
					
					let isExternal = URLIsExternal(linkURL, localHost: localHost)
					
					if isExternal {
						aExternalLinkElements.append(aLinkElement!)
						uniqueExternalPageURLs.insertReturningConformedURLIfNew(linkURL)
					}
					else {
						aLocalLinkElements.append(aLinkElement!)
						uniqueLocalPageURLs.insertReturningConformedURLIfNew(linkURL)
					}
				}
			}
			self.aLocalLinkElements = aLocalLinkElements
			self.aExternalLinkElements = aExternalLinkElements
			self.uniqueLocalPageURLs = uniqueLocalPageURLs
			self.uniqueExternalPageURLs = uniqueExternalPageURLs
			
			document.enumerateElements(withCSS: "img[src]") { (imgElement, index, stop) in
				if
					let imageURLString = imgElement?["src"] as? String,
					let imageURL = URL(string: imageURLString, relativeTo: localURL)
				{
					//let isExternal = URLIsExternal(linkURL, localHost: localHost)
					
					imageElements.append(imgElement!)
					imageURLs.insert(imageURL)
				}
			}
			self.imageElements = imageElements
			self.imageURLs = imageURLs
			
			h1Elements = document.allElementsWithCSS("h1")
			
			richSnippetElements = [] //TODO:
		} catch let error as NSError {
			document = nil
			stringEncoding = nil
			
			pageTitleElements = []
			
			metaDescriptionElements = []
			openGraphElements = []
			
			uniqueFeedURLs = UniqueURLArray()
			feedLinkElements = []
			
			uniqueExternalPageURLs = UniqueURLArray()
			aExternalLinkElements = []
			
			uniqueLocalPageURLs = UniqueURLArray()
			
			aLocalLinkElements = []
			
			imageURLs = Set<URL>()
			imageElements = []
			
			h1Elements = []
			richSnippetElements = []
			
			preBodyByteCount = nil
		}
	}
	
	public var HTMLHeadData: Data? {
		if let preBodyByteCount = preBodyByteCount {
			return data.subdata(in: 0..<preBodyByteCount)
		}
		
		return nil
	}
	
	public var HTMLBodyData: Data? {
		if let preBodyByteCount = preBodyByteCount {
			return data.subdata(in: preBodyByteCount..<(data.count - preBodyByteCount))
		}
		
		return nil
	}
	
	public var stringContent: String? {
		return String(data: data, encoding: stringEncoding)
		//return data.stringRepresentationUsingONOXMLDocumentHints(document)
	}
	
	public var HTMLHeadStringContent: String? {
		if let data = HTMLHeadData {
			return String(data: data, encoding: stringEncoding)
		}
		else {
			return nil
		}
		//return HTMLHeadData?.stringRepresentationUsingONOXMLDocumentHints(document)
	}
	
	public var HTMLBodyStringContent: String? {
		if let data = HTMLBodyData {
			return String(data: data, encoding: stringEncoding)
		}
		else {
			return nil
		}
		//return HTMLBodyData?.stringRepresentationUsingONOXMLDocumentHints(document)
	}
}



public struct ResourceInfo {
	public let requestedURL: URL
	public let finalURL: URL?
	public let statusCode: Int
	public let baseContentType: BaseContentType
	public let MIMEType: MIMETypeString?
	
	public let byteCount: Int?
	public let contentInfo: PageContentInfo?
}

public typealias PageInfo = ResourceInfo


public struct RequestRedirectionInfo {
	let sourceRequest: URLRequest
	let nextRequest: URLRequest
	public let statusCode: Int
	public let MIMEType: MIMETypeString?
}
