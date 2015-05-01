//
//  PageMapper.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 24/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


let JUST_USE_FINAL_URLS = true


public class PageMapper {
	public let primaryURL: NSURL
	public let crawlsFoundURLs: Bool
	public let maximumDepth: UInt
	
	public internal(set) var additionalURLs = [NSURL]()
	
	
	internal(set) var requestedURLsUnique = UniqueURLArray()
	
	public internal(set) var loadedURLToPageInfo = [NSURL: PageInfo]()
	public internal(set) var requestedURLToDestinationURL = [NSURL: NSURL]()
	public internal(set) var requestedURLToResponseType = [NSURL: PageResponseType]()
	
	public func hasFinishedRequestingURL(requestedURL: NSURL) -> Bool {
		return requestedURLToResponseType[requestedURL] != nil
	}
	
	public internal(set) var externalURLs = Set<NSURL>()
	
	internal(set) var requestedLocalPageURLsUnique = UniqueURLArray()
	public var localPageURLsOrdered: [NSURL] {
		return requestedLocalPageURLsUnique.orderedURLs
	}
	
	internal(set) var requestedImageURLsUnique = UniqueURLArray()
	public var imageURLsOrdered: [NSURL] {
		return requestedImageURLsUnique.orderedURLs
	}
	
	var requestedFeedURLsUnique = UniqueURLArray()
	public var feedURLsOrdered: [NSURL] {
		return requestedFeedURLsUnique.orderedURLs
	}
	
	var baseContentTypeToResponseTypeToURLCount = [BaseContentType: [PageResponseType: UInt]]()
	
	
	//var ignoresNoFollows = false
	public internal(set) var paused = false
	var queuedURLsToRequest = [(NSURL, BaseContentType, UInt)]()
	
	public var didUpdateCallback: ((pageURL: NSURL) -> Void)?
	
	private static let defaultMaximumDefault: UInt = 10
	
	
	public init(primaryURL: NSURL, crawlsFoundURLs: Bool = true, maximumDepth: UInt = defaultMaximumDefault) {
		self.primaryURL = conformURL(primaryURL)!.absoluteURL!
		self.crawlsFoundURLs = crawlsFoundURLs
		self.maximumDepth = maximumDepth
	}
	
	public func reload() {
		loadedURLToPageInfo.removeAll()
		externalURLs.removeAll()
		requestedLocalPageURLsUnique.removeAll()
		
		requestedLocalPageURLsUnique.insertReturningConformedURLIfNew(primaryURL)
		retrieveInfoForPageWithURL(primaryURL, expectedBaseContentType: .LocalHTMLPage, currentDepth: 0)
	}
	
	public func crawlAdditionalURL(URL: NSURL) {
		additionalURLs.append(URL)
		retrieveInfoForPageWithURL(URL, expectedBaseContentType: .LocalHTMLPage, currentDepth: 0)
	}
	
	public func pageInfoForRequestedURL(URL: NSURL) -> PageInfo? {
		if JUST_USE_FINAL_URLS {
			return loadedURLToPageInfo[URL]
		}
		else if let destinationURL = requestedURLToDestinationURL[URL] {
			return loadedURLToPageInfo[destinationURL]
		}
		else {
			return nil
		}
	}
	
	private func retrieveInfoForPageWithURL(pageURL: NSURL, expectedBaseContentType: BaseContentType, currentDepth: UInt) {
		if !paused {
			if let pageURL = requestedURLsUnique.insertReturningConformedURLIfNew(pageURL) {
				PageInfo.retrieveInfoForPageWithURL(pageURL, completionHandler: { [weak self] (pageInfo) in
					// completionHandler is called on main queue
					self?.didRetrieveInfo(pageInfo, forPageWithRequestedURL: pageURL, expectedBaseContentType: expectedBaseContentType, currentDepth: currentDepth)
					})
			}
		}
		else {
			queuedURLsToRequest.append((pageURL, expectedBaseContentType, currentDepth))
		}
	}
	
	private func didRetrieveInfo(pageInfo: PageInfo, forPageWithRequestedURL requestedPageURL: NSURL, expectedBaseContentType: BaseContentType, currentDepth: UInt) {
		let responseType = PageResponseType(statusCode: pageInfo.statusCode)
		requestedURLToResponseType[requestedPageURL] = responseType
		
		let actualBaseContentType = pageInfo.baseContentType
		
		baseContentTypeToResponseTypeToURLCount.updateValueForKey(actualBaseContentType) { responseTypeToURLCount in
			var responseTypeToURLCount = responseTypeToURLCount ?? [PageResponseType: UInt]()
			responseTypeToURLCount.updateValueForKey(responseType) { count in
				return (count ?? 0) + 1
			}
			return responseTypeToURLCount
		}
		
		if let finalURL = pageInfo.finalURL {
			requestedURLToDestinationURL[requestedPageURL] = finalURL
			loadedURLToPageInfo[finalURL] = pageInfo
			
			if JUST_USE_FINAL_URLS {
				switch actualBaseContentType {
				case .LocalHTMLPage:
					requestedLocalPageURLsUnique.insertReturningConformedURLIfNew(finalURL)
				case .Image:
					requestedImageURLsUnique.insertReturningConformedURLIfNew(finalURL)
				case .Feed:
					requestedFeedURLsUnique.insertReturningConformedURLIfNew(finalURL)
				case .Text:
					fallthrough
				default:
					break
				}
			}
			
			let childDepth = currentDepth + 1
			let processChildren = childDepth <= maximumDepth
			let crawl = crawlsFoundURLs
			
			if let contentInfo = pageInfo.contentInfo where processChildren {
				externalURLs.unionInPlace(contentInfo.externalURLs)
				
				for pageURL in contentInfo.localPageURLs {
					if JUST_USE_FINAL_URLS {
						if crawl {
							retrieveInfoForPageWithURL(pageURL, expectedBaseContentType: .LocalHTMLPage, currentDepth: childDepth)
						}
					}
					else if let pageURLPath = pageURL.relativePath where pageURLPath != "" {
						if let pageURL = requestedLocalPageURLsUnique.insertReturningConformedURLIfNew(pageURL) {
							if crawl {
								retrieveInfoForPageWithURL(pageURL, expectedBaseContentType: .LocalHTMLPage, currentDepth: childDepth)
							}
						}
					}
				}
				
				for imageURL in contentInfo.imageURLs {
					if JUST_USE_FINAL_URLS {
						if crawl {
							retrieveInfoForPageWithURL(imageURL, expectedBaseContentType: .Image, currentDepth: childDepth)
						}
					}
					else if let imageURL = requestedImageURLsUnique.insertReturningConformedURLIfNew(imageURL) {
						if crawl {
							retrieveInfoForPageWithURL(imageURL, expectedBaseContentType: .Image, currentDepth: childDepth)
						}
					}
				}
				
				for feedURL in contentInfo.feedURLs {
					if JUST_USE_FINAL_URLS {
						if crawl {
							retrieveInfoForPageWithURL(feedURL, expectedBaseContentType: .Feed, currentDepth: childDepth)
						}
					}
					else if let feedURL = requestedFeedURLsUnique.insertReturningConformedURLIfNew(feedURL) {
						if crawl {
							retrieveInfoForPageWithURL(feedURL, expectedBaseContentType: .Feed, currentDepth: childDepth)
						}
					}
				}
			}
		}
		
		self.didUpdateCallback?(pageURL: requestedPageURL)
	}
	
	public func pauseCrawling() {
		assert(crawlsFoundURLs, "Must have been initialized with crawlsFoundURLs = true")
		
		if !paused {
			paused = true
		}
	}
	
	public func resumeCrawling() {
		assert(crawlsFoundURLs, "Must have been initialized with crawlsFoundURLs = true")
		
		paused = false
		
		for (pendingURL, baseContentType, currentDepth) in queuedURLsToRequest {
			retrieveInfoForPageWithURL(pendingURL, expectedBaseContentType: baseContentType, currentDepth: currentDepth)
		}
		queuedURLsToRequest.removeAll()
	}
	
	public func cancel() {
		paused = true
		
		didUpdateCallback = nil
	}
}
