//
//  PageMapper.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 24/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


let JUST_USE_FINAL_URLS = true


public struct MappableURL {
	public let primaryURL: NSURL
	public let localHost: String
}

extension MappableURL {
	public init?(primaryURL: NSURL) {
		if let primaryURL = conformURL(primaryURL)?.absoluteURL {
			if let localHost = primaryURL.host {
				self.primaryURL = primaryURL
				self.localHost = localHost
				return
			}
		}
		
		return nil
	}
}


public class PageMapper {
	public let primaryURL: NSURL
	public let crawlsFoundURLs: Bool
	public let maximumDepth: UInt
	let localHost: String
	
	public internal(set) var additionalURLs = [NSURL]()
	
	//var ignoresNoFollows = false
	
	
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
	
	public var redirectedSourceURLToInfo = [NSURL: RequestRedirectionInfo]()
	public var redirectedDestinationURLToInfo = [NSURL: RequestRedirectionInfo]()
	
	
	private let infoRequestQueue: PageInfoRequestQueue
	
	private enum State {
		case Idle
		case Crawling
		case Paused
	}
	
	private var state: State = .Idle
	public var isCrawling: Bool {
		return state == .Crawling
	}
	public var paused: Bool {
		return state == .Paused
	}
	
	var queuedURLsToRequestWhilePaused = [(NSURL, BaseContentType, UInt)]()
	
	public var didUpdateCallback: ((pageURL: NSURL) -> Void)?
	
	private static let defaultMaximumDefault: UInt = 10
	
	
	public init(mappableURL: MappableURL, crawlsFoundURLs: Bool = true, maximumDepth: UInt = defaultMaximumDefault) {
		self.primaryURL = mappableURL.primaryURL
		self.localHost = mappableURL.localHost
		self.crawlsFoundURLs = crawlsFoundURLs
		self.maximumDepth = maximumDepth
		
		infoRequestQueue = PageInfoRequestQueue()
		infoRequestQueue.willPerformHTTPRedirection = { [weak self] redirectionInfo in
			if
				let pageMapper = self,
				let sourceURL = redirectionInfo.sourceRequest.URL,
				let nextURL = redirectionInfo.nextRequest.URL
			{
				#if DEBUG
					println("REDIRECT \(sourceURL) \(nextURL)")
				#endif
				
				pageMapper.redirectedSourceURLToInfo[sourceURL] = redirectionInfo
				pageMapper.redirectedDestinationURLToInfo[nextURL] = redirectionInfo
			}
		}
	}
	
	public func addAdditionalURL(URL: NSURL) {
		additionalURLs.append(URL)
		
		if isCrawling {
			retrieveInfoForPageWithURL(URL, expectedBaseContentType: .LocalHTMLPage, currentDepth: 0)
		}
	}
	
	func clearLoadedInfo() {
		requestedURLsUnique.removeAll()
		loadedURLToPageInfo.removeAll()
		requestedURLToDestinationURL.removeAll()
		requestedURLToResponseType.removeAll()
		
		requestedLocalPageURLsUnique.removeAll()
		externalURLs.removeAll()
		requestedImageURLsUnique.removeAll()
		requestedFeedURLsUnique.removeAll()
		
		redirectedSourceURLToInfo.removeAll()
		redirectedDestinationURLToInfo.removeAll()
		
		queuedURLsToRequestWhilePaused.removeAll()
	}
	
	public func reload() {
		state = .Crawling
		
		clearLoadedInfo()
		
		retrieveInfoForPageWithURL(primaryURL, expectedBaseContentType: .LocalHTMLPage, currentDepth: 0)
		
		for additionalURL in additionalURLs {
			retrieveInfoForPageWithURL(additionalURL, expectedBaseContentType: .LocalHTMLPage, currentDepth: 0)
		}
	}
	
	public func pageInfoForRequestedURL(URL: NSURL) -> PageInfo? {
		if JUST_USE_FINAL_URLS {
			if let URL = conformURL(URL) {
				return loadedURLToPageInfo[URL]
			}
		}
		else if let destinationURL = requestedURLToDestinationURL[URL] {
			return loadedURLToPageInfo[destinationURL]
		}
		
		return nil
	}
	
	private func retrieveInfoForPageWithURL(pageURL: NSURL, expectedBaseContentType: BaseContentType, currentDepth: UInt) {
		if linkedURLLooksLikeFileDownload(pageURL) {
			return
		}
		
		if !paused {
			if let pageURL = requestedURLsUnique.insertReturningConformedURLIfNew(pageURL) {
				let infoRequest = PageInfoRequest(URL: pageURL, completionHandler: { [weak self] (pageInfo) in
					if let didRetrieveInfo = self?.didRetrieveInfo {
						didRetrieveInfo(pageInfo, forPageWithRequestedURL: pageURL, expectedBaseContentType: expectedBaseContentType, currentDepth: currentDepth)
					}
				})
				infoRequestQueue.addRequest(infoRequest)
			}
		}
		else {
			queuedURLsToRequestWhilePaused.append((pageURL, expectedBaseContentType, currentDepth))
		}
	}
	
	private func didRetrieveInfo(pageInfo: PageInfo, forPageWithRequestedURL requestedPageURL: NSURL, expectedBaseContentType: BaseContentType, currentDepth: UInt) {
		let responseType = PageResponseType(statusCode: pageInfo.statusCode)
		requestedURLToResponseType[requestedPageURL] = responseType
		
		if responseType == .Redirects {
			#if DEBUG
				println("REDIRECT \(requestedPageURL) \(pageInfo.finalURL)")
			#endif
		}
		
		if let finalURL = pageInfo.finalURL {
			requestedURLToDestinationURL[requestedPageURL] = finalURL
			loadedURLToPageInfo[finalURL] = pageInfo
			
			let actualBaseContentType = pageInfo.baseContentType
			
			baseContentTypeToResponseTypeToURLCount.updateValueForKey(actualBaseContentType) { responseTypeToURLCount in
				var responseTypeToURLCount = responseTypeToURLCount ?? [PageResponseType: UInt]()
				responseTypeToURLCount.updateValueForKey(responseType) { count in
					return (count ?? 0) + 1
				}
				return responseTypeToURLCount
			}
			
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
			let crawl = crawlsFoundURLs && isCrawling
			
			if let contentInfo = pageInfo.contentInfo where processChildren {
				for pageURL in contentInfo.externalPageURLs {
					externalURLs.insert(pageURL)
				}
				
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
			state = .Paused
		}
	}
	
	public func resumeCrawling() {
		assert(crawlsFoundURLs, "Must have been initialized with crawlsFoundURLs = true")
		
		state = .Crawling
		
		for (pendingURL, baseContentType, currentDepth) in queuedURLsToRequestWhilePaused {
			retrieveInfoForPageWithURL(pendingURL, expectedBaseContentType: baseContentType, currentDepth: currentDepth)
		}
		queuedURLsToRequestWhilePaused.removeAll()
	}
	
	public func cancel() {
		state = .Idle
		//clearLoadedInfo()
		
		didUpdateCallback = nil
		
		infoRequestQueue.cancelAll(clearAll: true)
	}
}
