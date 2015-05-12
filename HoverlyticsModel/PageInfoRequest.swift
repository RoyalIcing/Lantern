//
//  PageInfoRequest.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 2/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Alamofire
import Ono


public class PageInfoRequest {
	typealias CompletionHandler = (info: PageInfo, infoRequest: PageInfoRequest) -> Void
	
	public let URL: NSURL
	public let includingContent: Bool
	public let method: Alamofire.Method
	public let expectedBaseContentType: BaseContentType
	let completionHandler: CompletionHandler
	var request: Alamofire.Request?
	
	init(URL: NSURL, expectedBaseContentType: BaseContentType, includingContent: Bool = false, completionHandler: CompletionHandler) {
		self.URL = URL
		self.expectedBaseContentType = expectedBaseContentType
		self.includingContent = includingContent
		self.method = includingContent ? .GET : .HEAD
		self.completionHandler = completionHandler
	}
	
	func copyNotIncludingContent() -> PageInfoRequest {
		return PageInfoRequest(URL: URL, expectedBaseContentType: expectedBaseContentType, includingContent: false, completionHandler: completionHandler)
	}
}

private class PageInfoReference {
	let info: PageInfo
	
	init(info: PageInfo) {
		self.info = info
	}
}

class PageInfoRequestQueue {
	let requestManager: Alamofire.Manager
	let maximumActiveRequests = 5
	var activeRequests = [PageInfoRequest]()
	var pendingRequests = [PageInfoRequest]()
	var willPerformHTTPRedirection: ((redirectionInfo: RequestRedirectionInfo) -> Void)?
	var didFinishWithRequest: ((infoRequest: PageInfoRequest) -> Void)?
	
	init() {
		let manager = Alamofire.Manager()
		self.requestManager = manager
		
		let managerDelegate = manager.delegate
		managerDelegate.taskWillPerformHTTPRedirection = { [weak self] session, task, response, request in
			#if DEBUG
				println("taskWillPerformHTTPRedirection")
			#endif
			
			if let willPerformHTTPRedirection = self?.willPerformHTTPRedirection {
				let info = RequestRedirectionInfo(sourceRequest: task.originalRequest, nextRequest: request, statusCode: response.statusCode, MIMEType: MIMETypeString(response.MIMEType))
				willPerformHTTPRedirection(redirectionInfo: info)
			}
			
			return request
		}
	}
	
	func addRequestForURL(URL: NSURL, expectedBaseContentType: BaseContentType, includingContent: Bool, highPriority: Bool = false, completionHandler: PageInfoRequest.CompletionHandler) -> PageInfoRequest {
		let infoRequest = PageInfoRequest(URL: URL, expectedBaseContentType: expectedBaseContentType, includingContent: includingContent, completionHandler: completionHandler)
		
		if highPriority || activeRequests.count < maximumActiveRequests {
			performRequest(infoRequest)
		}
		else {
			pendingRequests.append(infoRequest)
		}
		
		return infoRequest
	}
	
	func downgradePendingRequestsToNotIncludeContent(decider: ((PageInfoRequest) -> Bool)) {
		pendingRequests = pendingRequests.map { request in
			if request.includingContent && decider(request) {
				return request.copyNotIncludingContent()
			}
			else {
				return request
			}
		}
	}
	
	func cancelRequestForURL(URL: NSURL) {
		let URLAbsoluteString = URL.absoluteString
		
		func requestContainsURL(infoRequest: PageInfoRequest) -> Bool {
			return infoRequest.URL.absoluteString == URLAbsoluteString
		}
		
		for (index, request) in enumerate(pendingRequests) {
			if requestContainsURL(request) {
				pendingRequests.removeAtIndex(index)
				break
			}
		}
	}
	
	private func performNextPendingRequest() {
		// Perform the request next at the top of the list.
		if let infoRequest = pendingRequests.first {
			pendingRequests.removeAtIndex(0)
			performRequest(infoRequest)
		}
	}
	
	private func activeRequestDidComplete(infoRequest: PageInfoRequest, withInfo info: PageInfo) {
		infoRequest.completionHandler(info: info, infoRequest: infoRequest)
		
		// Remove from active requests
		for (index, someRequest) in enumerate(activeRequests) {
			if someRequest === infoRequest {
				activeRequests.removeAtIndex(index)
				break
			}
		}
		
		// Start the next request in queue going
		performNextPendingRequest()
	}
	
	private func performRequest(infoRequest: PageInfoRequest) {
		activeRequests.append(infoRequest)
		
		// An Alamofire serializer to perform the parsing etc on the request’s background queue.
		let serializer: Alamofire.Request.Serializer = { URLRequest, response, data in
			if let response = response {
				let requestedURL = infoRequest.URL
				let MIMEType = MIMETypeString(response.MIMEType)
				let baseContentType: BaseContentType = MIMEType?.baseContentType ?? .Unknown
				
				let byteCount: Int?
				let contentInfo: PageContentInfo?
				if let data = data where infoRequest.includingContent {
					byteCount = data.length
					contentInfo = PageContentInfo(data: data, localURL: requestedURL)
				}
				else {
					byteCount = nil
					contentInfo = nil
				}
				
				var info = PageInfo(requestedURL: requestedURL, finalURL: response.URL, statusCode: response.statusCode, baseContentType: baseContentType, MIMEType: MIMEType, byteCount: byteCount, contentInfo: contentInfo)
				
				// Result expected is AnyObject, so we can’t pass a struct here unfortunately.
				return (PageInfoReference(info: info), nil)
			}
			else {
				return (nil, nil)
			}
		}
		
		// Perform the request
		let requestedURL = infoRequest.URL
		infoRequest.request = requestManager
			.request(infoRequest.method, requestedURL)
			.response(serializer: serializer) { (URLRequest, response, infoReference, error) in
				if
					let response = response,
					let infoReference = infoReference as? PageInfoReference
				{
					let info = infoReference.info
					self.activeRequestDidComplete(infoRequest, withInfo: info)
				}
		}
	}
	
	func cancelAll(clearAll: Bool = true) {
		// Cancel any requests being performed
		for infoRequest in activeRequests {
			infoRequest.request?.cancel()
			infoRequest.request = nil
		}
		
		if clearAll {
			pendingRequests.removeAll()
		}
		else {
			// Put imcomplete requests back on the queue
			pendingRequests.splice(activeRequests, atIndex: 0)
		}
		
		activeRequests.removeAll()
	}
}

