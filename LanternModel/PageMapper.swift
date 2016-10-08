//
//	PageMapper.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 24/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


private let JUST_USE_FINAL_URLS = true


public struct MappableURL {
	public let primaryURL: URL
	public let localHost: String
}

extension MappableURL {
	public init?(primaryURL: URL) {
		guard let
			primaryURL = conformURL(primaryURL)?.absoluteURL,
			let localHost = primaryURL.host
		else {
			return nil
		}
		
		self.primaryURL = primaryURL
		self.localHost = localHost
	}
}


open class PageMapper {
	open let primaryURL: URL
	open let crawlsFoundURLs: Bool
	open let maximumDepth: UInt
	let localHost: String
	
	open internal(set) var additionalURLs = [URL]()
	
	//var ignoresNoFollows = false
	
	
	internal(set) var requestedURLsUnique = UniqueURLArray()
	
	open internal(set) var loadedURLToPageInfo = [URL: PageInfo]()
	open internal(set) var requestedURLToDestinationURL = [URL: URL]()
	open internal(set) var requestedURLToResponseType = [URL: PageResponseType]()
	
	open func hasFinishedRequestingURL(_ requestedURL: URL) -> Bool {
		return requestedURLToResponseType[requestedURL] != nil
	}
	
	open internal(set) var externalURLs = Set<URL>()
	
	internal(set) var requestedLocalPageURLsUnique = UniqueURLArray()
	open var localPageURLsOrdered: [URL] {
		return requestedLocalPageURLsUnique.orderedURLs as [URL]
	}
	
	internal(set) var requestedImageURLsUnique = UniqueURLArray()
	open var imageURLsOrdered: [URL] {
		return requestedImageURLsUnique.orderedURLs as [URL]
	}
	
	var requestedFeedURLsUnique = UniqueURLArray()
	open var feedURLsOrdered: [URL] {
		return requestedFeedURLsUnique.orderedURLs as [URL]
	}
	
	var baseContentTypeToResponseTypeToURLCount = [BaseContentType: [PageResponseType: UInt]]()
	var baseContentTypeToSummedByteCount = [BaseContentType: UInt]()
	var baseContentTypeToMaximumByteCount = [BaseContentType: UInt]()
	
	open var redirectedSourceURLToInfo = [URL: RequestRedirectionInfo]()
	open var redirectedDestinationURLToInfo = [URL: RequestRedirectionInfo]()
	
	
	fileprivate let infoRequestQueue: PageInfoRequestQueue
	
	fileprivate enum State {
		case idle
		case crawling
		case paused
	}
	
	fileprivate var state: State = .idle
	open var isCrawling: Bool {
		return state == .crawling
	}
	open var paused: Bool {
		return state == .paused
	}
	
	var queuedURLsToRequestWhilePaused = [(URL, BaseContentType, UInt?)]()
	
	open var didUpdateCallback: ((_ pageURL: URL) -> Void)?
	
	fileprivate static let defaultMaximumDefault: UInt = 10
	
	
	public init(mappableURL: MappableURL, crawlsFoundURLs: Bool = true, maximumDepth: UInt = defaultMaximumDefault) {
		self.primaryURL = mappableURL.primaryURL
		self.localHost = mappableURL.localHost
		self.crawlsFoundURLs = crawlsFoundURLs
		self.maximumDepth = maximumDepth
		
		infoRequestQueue = PageInfoRequestQueue()
		infoRequestQueue.willPerformHTTPRedirection = { [weak self] redirectionInfo in
			if
				let pageMapper = self,
				let sourceURL = redirectionInfo.sourceRequest.url,
				let nextURL = redirectionInfo.nextRequest.url
			{
				#if DEBUG
					print("REDIRECT \(sourceURL) \(nextURL)")
				#endif
				
				pageMapper.redirectedSourceURLToInfo[sourceURL] = redirectionInfo
				pageMapper.redirectedDestinationURLToInfo[nextURL] = redirectionInfo
			}
		}
	}
	
	open func addAdditionalURL(_ URL: Foundation.URL) {
		additionalURLs.append(URL)
		
		if isCrawling {
			retrieveInfoForPageWithURL(URL, expectedBaseContentType: .localHTMLPage, currentDepth: 0)
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
		
		baseContentTypeToResponseTypeToURLCount.removeAll()
		baseContentTypeToSummedByteCount.removeAll()
	}
	
	open func reload() {
		state = .crawling
		
		clearLoadedInfo()
		
		retrieveInfoForPageWithURL(primaryURL, expectedBaseContentType: .localHTMLPage, currentDepth: 0)
		
		for additionalURL in additionalURLs {
			retrieveInfoForPageWithURL(additionalURL, expectedBaseContentType: .localHTMLPage, currentDepth: 0)
		}
	}
	
	open func pageInfoForRequestedURL(_ URL: Foundation.URL) -> PageInfo? {
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
	
	fileprivate func retrieveInfoForPageWithURL(_ pageURL: URL, expectedBaseContentType: BaseContentType, currentDepth: UInt?) {
		if linkedURLLooksLikeFileDownload(pageURL) {
			return
		}
		
		if !paused {
			if let pageURL = requestedURLsUnique.insertReturningConformedURLIfNew(pageURL) {
				let includeContent = !hasReachedMaximumByteLimitForBaseContentType(expectedBaseContentType)
				
				infoRequestQueue.addRequestForURL(pageURL, expectedBaseContentType: expectedBaseContentType, includingContent: includeContent) { [weak self] (info, infoRequest) in
					self?.didRetrieveInfo(info, forPageWithRequestedURL: pageURL, expectedBaseContentType: expectedBaseContentType, currentDepth: currentDepth)
				}
			}
		}
		else {
			queuedURLsToRequestWhilePaused.append((pageURL, expectedBaseContentType, currentDepth))
		}
	}
	
	open func priorityRequestContentIfNeededForURL(_ URL: Foundation.URL, expectedBaseContentType: BaseContentType) {
		if let
			info = pageInfoForRequestedURL(URL),
			let contentInfo = info.contentInfo
		{
			return
		}
		
		infoRequestQueue.cancelRequestForURL(URL)
		infoRequestQueue.addRequestForURL(URL, expectedBaseContentType: expectedBaseContentType, includingContent: true, highPriority: true) { [weak self] (info, infoRequest) in
			self?.didRetrieveInfo(info, forPageWithRequestedURL: URL, expectedBaseContentType: expectedBaseContentType, currentDepth: nil)
		}
	}
	
	fileprivate func didRetrieveInfo(_ pageInfo: PageInfo, forPageWithRequestedURL requestedPageURL: URL, expectedBaseContentType: BaseContentType, currentDepth: UInt?) {
		let responseType = PageResponseType(statusCode: pageInfo.statusCode)
		requestedURLToResponseType[requestedPageURL] = responseType
		
		if responseType == .redirects {
			#if DEBUG
				print("REDIRECT \(requestedPageURL) \(pageInfo.finalURL)")
			#endif
		}
		
		if let finalURL = pageInfo.finalURL {
			requestedURLToDestinationURL[requestedPageURL] = finalURL as URL
			loadedURLToPageInfo[finalURL as URL] = pageInfo
			
			let actualBaseContentType = pageInfo.baseContentType
			
			baseContentTypeToResponseTypeToURLCount.updateValueForKey(actualBaseContentType) { responseTypeToURLCount in
				var responseTypeToURLCount = responseTypeToURLCount ?? [PageResponseType: UInt]()
				responseTypeToURLCount.updateValueForKey(responseType) { count in
					return (count ?? 0) + 1
				}
				return responseTypeToURLCount
			}
			
			baseContentTypeToSummedByteCount.updateValueForKey(actualBaseContentType) { summedByteCount in
				return (summedByteCount ?? 0) + UInt(pageInfo.byteCount ?? 0)
			}
			
			if hasReachedMaximumByteLimitForBaseContentType(actualBaseContentType) {
				cancelPendingRequestsForBaseContentType(actualBaseContentType)
			}
			
			if JUST_USE_FINAL_URLS {
				switch actualBaseContentType {
				case .localHTMLPage:
					requestedLocalPageURLsUnique.insertReturningConformedURLIfNew(finalURL)
				case .image:
					requestedImageURLsUnique.insertReturningConformedURLIfNew(finalURL)
				case .feed:
					requestedFeedURLsUnique.insertReturningConformedURLIfNew(finalURL)
				case .text:
					fallthrough
				default:
					break
				}
			}
			
			if let
				childDepth = currentDepth.map({ $0 + 1 }),
				let contentInfo = pageInfo.contentInfo
				, childDepth <= maximumDepth
			{
				let crawl = crawlsFoundURLs && isCrawling
				
				for pageURL in contentInfo.externalPageURLs {
					externalURLs.insert(pageURL as URL)
				}
				
				for pageURL in contentInfo.localPageURLs {
					if JUST_USE_FINAL_URLS {
						if crawl {
							retrieveInfoForPageWithURL(pageURL as URL, expectedBaseContentType: .localHTMLPage, currentDepth: childDepth)
						}
					}
					else if pageURL.relativePath != "" {
						if let pageURL = requestedLocalPageURLsUnique.insertReturningConformedURLIfNew(pageURL) {
							if crawl {
								retrieveInfoForPageWithURL(pageURL, expectedBaseContentType: .localHTMLPage, currentDepth: childDepth)
							}
						}
					}
				}
				
				for imageURL in contentInfo.imageURLs {
					if JUST_USE_FINAL_URLS {
						if crawl {
							retrieveInfoForPageWithURL(imageURL as URL, expectedBaseContentType: .image, currentDepth: childDepth)
						}
					}
					else if let imageURL = requestedImageURLsUnique.insertReturningConformedURLIfNew(imageURL) {
						if crawl {
							retrieveInfoForPageWithURL(imageURL, expectedBaseContentType: .image, currentDepth: childDepth)
						}
					}
				}
				
				for feedURL in contentInfo.feedURLs {
					if JUST_USE_FINAL_URLS {
						if crawl {
							retrieveInfoForPageWithURL(feedURL as URL, expectedBaseContentType: .feed, currentDepth: childDepth)
						}
					}
					else if let feedURL = requestedFeedURLsUnique.insertReturningConformedURLIfNew(feedURL) {
						if crawl {
							retrieveInfoForPageWithURL(feedURL, expectedBaseContentType: .feed, currentDepth: childDepth)
						}
					}
				}
			}
		}
		
		self.didUpdateCallback?(requestedPageURL)
	}
	
	func cancelPendingRequestsForBaseContentType(_ type: BaseContentType) {
		infoRequestQueue.downgradePendingRequestsToNotIncludeContent { request in
			return request.expectedBaseContentType == type
		}
	}
	
	open func pauseCrawling() {
		assert(crawlsFoundURLs, "Must have been initialized with crawlsFoundURLs = true")
		
		if !paused {
			state = .paused
		}
	}
	
	open func resumeCrawling() {
		assert(crawlsFoundURLs, "Must have been initialized with crawlsFoundURLs = true")
		
		state = .crawling
		
		for (pendingURL, baseContentType, currentDepth) in queuedURLsToRequestWhilePaused {
			retrieveInfoForPageWithURL(pendingURL, expectedBaseContentType: baseContentType, currentDepth: currentDepth)
		}
		queuedURLsToRequestWhilePaused.removeAll()
	}
	
	open func cancel() {
		state = .idle
		
		didUpdateCallback = nil
		
		infoRequestQueue.cancelAll(true)
	}
	
	open func summedByteCountForBaseContentType(_ type: BaseContentType) -> UInt {
		return baseContentTypeToSummedByteCount[type] ?? 0
	}
	
	open func maximumByteCountForBaseContentType(_ type: BaseContentType) -> UInt? {
		return baseContentTypeToMaximumByteCount[type]
	}
	
	open func setMaximumByteCount(_ maximumByteCount: UInt?, forBaseContentType type: BaseContentType) {
		if let maximumByteCount = maximumByteCount {
			baseContentTypeToMaximumByteCount[type] = maximumByteCount
		}
		else {
			baseContentTypeToMaximumByteCount.removeValue(forKey: type)
		}
	}
	
	open func hasReachedMaximumByteLimitForBaseContentType(_ type: BaseContentType) -> Bool {
		if let maximumByteCount = maximumByteCountForBaseContentType(type) {
			return summedByteCountForBaseContentType(type) >= maximumByteCount
		}
		else {
			return false
		}
	}
}
