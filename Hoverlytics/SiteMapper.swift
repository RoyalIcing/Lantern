//
//  SiteMapper.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 24/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Alamofire
import Ono


typealias ONOXMLElementFilter = (element: ONOXMLElement) -> Bool


extension ONOXMLDocument {
	func allElementsWithCSS(selector: String, filter: ONOXMLElementFilter? = nil) -> [ONOXMLElement] {
		var elements = [ONOXMLElement]()
		self.enumerateElementsWithCSS(selector, usingBlock: { (element, index, stop) in
			if filter?(element: element) == false {
				return
			}
			elements.append(element)
		})
		return elements
	}
}


struct PageContentInfo {
	let pageTitle: String?
	//let pageTitleElement: ONOXMLElement?
	
	let metaDescriptionElements: [ONOXMLElement]
	let openGraphElements: [ONOXMLElement]
	
	let externalURLs: Set<NSURL>
	let localURLs: Set<NSURL>
	
	let aExternalLinkElements: [ONOXMLElement]
	let aLocalLinkElements: [ONOXMLElement]
	
	let h1Elements: [ONOXMLElement]
	let richSnippetElements: [ONOXMLElement]
	
	init(document: ONOXMLDocument, localURL: NSURL) {
		let titleElement = document.firstChildWithCSS("title")
		pageTitle = titleElement.stringValue()
		
		metaDescriptionElements = document.allElementsWithCSS("head meta[name][content]") { element in
			if let name = element.attributes["name"] as? String {
				return name.caseInsensitiveCompare("description") == .OrderedSame
			}
			
			return false
		}
		openGraphElements = document.allElementsWithCSS("head meta[property]") { element in
			if let name = element.attributes["property"] as? String {
				return name.rangeOfString("og:", options: .AnchoredSearch | .CaseInsensitiveSearch) != nil
			}
			
			return false
		}
		
		let localHost = localURL.host!
		var aLocalLinkElements = [ONOXMLElement]()
		var aExternalLinkElements = [ONOXMLElement]()
		var localURLs = Set<NSURL>()
		var externalURLs = Set<NSURL>()
		document.enumerateElementsWithCSS("a[href]", usingBlock: { (aLinkElement, index, stop) in
			if
				let linkURLString = aLinkElement.attributes["href"] as? String,
				let linkURL = NSURL(string: linkURLString, relativeToURL: localURL)
			{
				var isExternal = false
				if let linkHost = linkURL.host {
					if linkHost.caseInsensitiveCompare(localHost) != .OrderedSame {
						isExternal = true
					}
				}
				
				if isExternal {
					aExternalLinkElements.append(aLinkElement)
					externalURLs.insert(linkURL)
				}
				else {
					aLocalLinkElements.append(aLinkElement)
					localURLs.insert(linkURL)
				}
			}
		})
		self.aLocalLinkElements = aLocalLinkElements
		self.aExternalLinkElements = aExternalLinkElements
		self.localURLs = localURLs
		self.externalURLs = externalURLs
		
		h1Elements = document.allElementsWithCSS("h1")
		
		richSnippetElements = [] //TODO:
	}
}


struct PageInfo {
	let requestedURL: NSURL
	let finalURL: NSURL?
	let statusCode: Int
	let size: Int64?
	
	var contentInfo: PageContentInfo!
	
	static func retrieveInfoForPageWithURL(pageURL: NSURL, completionHandler: (pageInfo: PageInfo) -> Void) {
		Alamofire
			.request(.GET, pageURL)
			.response { (request, response, data, error) in
				if let response = response {
					var pageInfo = PageInfo(requestedURL: pageURL, finalURL: response.URL, statusCode: response.statusCode, size: response.expectedContentLength, contentInfo: nil)
					if let data = data as? NSData {
						var error: NSError?
						let document = ONOXMLDocument.HTMLDocumentWithData(data, error: &error)
						
						pageInfo.contentInfo = PageContentInfo(document: document, localURL: pageURL)
						
						completionHandler(pageInfo: pageInfo)
					}
				}
		}
	}
}


class SiteMapper {
	var primaryURL: NSURL
	var additionalURLs = [NSURL]()
	
	var URLToPageInfo = [NSURL:PageInfo]()
	var externalURLs = Set<NSURL>()
	var localURLPathsSet = Set<String>()
	var localURLsOrdered = Array<NSURL>()
	
	var mapsFoundURLs = true
	private(set) var cancelled = false
	
	typealias DidUpdateCallback = (pageURL: NSURL) -> Void
	var didUpdateCallback: DidUpdateCallback?
	
	init(primaryURL: NSURL) {
		self.primaryURL = primaryURL
	}
	
	func reload() {
		URLToPageInfo.removeAll()
		externalURLs.removeAll()
		localURLPathsSet.removeAll()
		localURLsOrdered.removeAll()
		
		retrieveInfoForPageWithURL(primaryURL)
	}
	
	private func didRetrieveInfo(pageInfo: PageInfo, forPageWithURL pageURL: NSURL) {
		self.URLToPageInfo[pageInfo.requestedURL] = pageInfo
		
		let retrieveChildURLs = !self.cancelled && self.mapsFoundURLs
		
		if let contentInfo = pageInfo.contentInfo {
			self.externalURLs.unionInPlace(contentInfo.externalURLs)
			
			for pageURL in contentInfo.localURLs {
				if let pageURLPath = pageURL.relativePath {
					if !self.localURLPathsSet.contains(pageURLPath) {
						self.localURLPathsSet.insert(pageURLPath)
						self.localURLsOrdered.append(pageURL)
						
						if retrieveChildURLs {
							self.retrieveInfoForPageWithURL(pageURL)
						}
					}
				}
			}
		}
		
		self.didUpdateCallback?(pageURL: pageInfo.requestedURL)
	}
	
	private func retrieveInfoForPageWithURL(pageURL: NSURL) {
		PageInfo.retrieveInfoForPageWithURL(pageURL, completionHandler: { [weak self] (pageInfo) in
			// completionHandler is called on main queue
			self?.didRetrieveInfo(pageInfo, forPageWithURL: pageURL)
		})
	}
	
	func cancel() {
		cancelled = true
	}
}