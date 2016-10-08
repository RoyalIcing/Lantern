//
//	PageInfoRequest.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 2/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Alamofire
import Ono
import Grain


open class PageInfoRequest {
	typealias CompletionHandler = (_ info: PageInfo, _ infoRequest: PageInfoRequest) -> Void
	
	open let URL: Foundation.URL
	open let includingContent: Bool
	open let method: Alamofire.HTTPMethod
	open let expectedBaseContentType: BaseContentType
	let completionHandler: CompletionHandler
	var request: Alamofire.Request?
	
	init(URL: Foundation.URL, expectedBaseContentType: BaseContentType, includingContent: Bool = false, completionHandler: @escaping CompletionHandler) {
		self.URL = URL
		self.expectedBaseContentType = expectedBaseContentType
		self.includingContent = includingContent
		self.method = includingContent ? Alamofire.HTTPMethod.get : Alamofire.HTTPMethod.head
		self.completionHandler = completionHandler
	}
	
	func copyNotIncludingContent() -> PageInfoRequest {
		return PageInfoRequest(URL: URL, expectedBaseContentType: expectedBaseContentType, includingContent: false, completionHandler: completionHandler)
	}
}


extension ResourceInfo {
	init(requestedURL: URL, includeContent: Bool, response: HTTPURLResponse, data: Data?) {
		let MIMEType = MIMETypeString(response.mimeType)
		let baseContentType: BaseContentType = MIMEType?.baseContentType ?? .unknown
		
		let byteCount: Int?
		let contentInfo: PageContentInfo?
		if let data = data , includeContent {
			byteCount = data.count
			contentInfo = PageContentInfo(data: data, localURL: requestedURL)
		}
		else {
			byteCount = nil
			contentInfo = nil
		}
		
		self.init(requestedURL: requestedURL, finalURL: response.url, statusCode: response.statusCode, baseContentType: baseContentType, MIMEType: MIMEType, byteCount: byteCount, contentInfo: contentInfo)
	}
	
	static func serializer(_ requestedURL: URL, includeContent: Bool) -> DataResponseSerializer<ResourceInfo> {
		return DataResponseSerializer<ResourceInfo> { request, response, data, error in
			guard error == nil else { return .failure(error!) }
			
			if let response = response {
				return .success(
					PageInfo(requestedURL: requestedURL, includeContent: includeContent, response: response, data: data)
				)
			}
			else {
				let error = AFError.responseSerializationFailed(reason: .inputDataNil)
				return .failure(error)
			}
		}
	}
}


public enum ResourceInfoRetrievalStage : StageProtocol {
	case getInfo(url: URL, requestManager: Alamofire.SessionManager)
	case getContent(url: URL, requestManager: Alamofire.SessionManager)
	
	case startedRequest(request: Alamofire.DataRequest, url: URL, includeContent: Bool)
	
	case success(info: PageInfo)
	
	public typealias Result = PageInfo
	
	enum ErrorKind: Error {
		case requestFailed(underlyingError: Error)
	}
	
	public func next() -> Deferred<ResourceInfoRetrievalStage> {
		switch self {
		case let .getInfo(url, requestManager):
			return Deferred.unit{
				let request = requestManager.request(url, method: .head)
				return .startedRequest(request: request, url: url, includeContent: false)
			}
			
		case let .getContent(url, requestManager):
			return Deferred.unit{
				let request = requestManager.request(url)
				return .startedRequest(request: request, url: url, includeContent: true)
			}
			
		case let .startedRequest(request, url, includeContent):
			return Deferred.future{ resolve in
				let serializer = ResourceInfo.serializer(url, includeContent: includeContent)
				request.response(responseSerializer: serializer) { response in
					switch response.result {
					case let .success(info):
						resolve{ .success(info: info) }
					case let .failure(error):
						resolve{ throw ErrorKind.requestFailed(underlyingError: error) }
					}
				}
			}
		case .success:
			completedStage(self)
		}
	}
	
	public var result: Result? {
		guard case let .success(result) = self else { return nil }
		return result
	}
}


class PageInfoRequestQueue {
	let requestManager: Alamofire.SessionManager
	let maximumActiveRequests = 5
	var activeRequests = [PageInfoRequest]()
	var pendingRequests = [PageInfoRequest]()
	var willPerformHTTPRedirection: ((_ redirectionInfo: RequestRedirectionInfo) -> Void)?
	var didFinishWithRequest: ((_ infoRequest: PageInfoRequest) -> Void)?
	
	init() {
		let manager = Alamofire.SessionManager()
		self.requestManager = manager
		
		let managerDelegate = manager.delegate
		managerDelegate.taskWillPerformHTTPRedirection = { [weak self] session, task, response, request in
			#if DEBUG
				print("taskWillPerformHTTPRedirection")
			#endif
			
			if let
				willPerformHTTPRedirection = self?.willPerformHTTPRedirection,
				let originalRequest = task.originalRequest
			{
				let info = RequestRedirectionInfo(sourceRequest: originalRequest, nextRequest: request, statusCode: response.statusCode, MIMEType: MIMETypeString(response.mimeType))
				willPerformHTTPRedirection(info)
			}
			
			return request
		}
	}
	
	func addRequestForURL(_ URL: Foundation.URL, expectedBaseContentType: BaseContentType, includingContent: Bool, highPriority: Bool = false, completionHandler: @escaping PageInfoRequest.CompletionHandler) -> PageInfoRequest? {
		let URL = URL.absoluteURL
		guard URL.host != nil else {
			return nil
		}
		
		let infoRequest = PageInfoRequest(URL: URL, expectedBaseContentType: expectedBaseContentType, includingContent: includingContent, completionHandler: completionHandler)
		
		if highPriority || activeRequests.count < maximumActiveRequests {
			performRequest(infoRequest)
		}
		else {
			pendingRequests.append(infoRequest)
		}
		
		return infoRequest
	}
	
	func downgradePendingRequestsToNotIncludeContent(_ decider: ((PageInfoRequest) -> Bool)) {
		pendingRequests = pendingRequests.map { request in
			if request.includingContent && decider(request) {
				return request.copyNotIncludingContent()
			}
			else {
				return request
			}
		}
	}
	
	func cancelRequestForURL(_ URL: Foundation.URL) {
		let URLAbsoluteString = URL.absoluteString
		
		func requestContainsURL(_ infoRequest: PageInfoRequest) -> Bool {
			return infoRequest.URL.absoluteString == URLAbsoluteString
		}
		
		for (index, request) in pendingRequests.enumerated() {
			if requestContainsURL(request) {
				pendingRequests.remove(at: index)
				break
			}
		}
	}
	
	fileprivate func performNextPendingRequest() {
		// Perform the request next at the top of the list.
		if let infoRequest = pendingRequests.first {
			pendingRequests.remove(at: 0)
			performRequest(infoRequest)
		}
	}
	
	fileprivate func activeRequestDidComplete(_ infoRequest: PageInfoRequest, withInfo info: PageInfo) {
		infoRequest.completionHandler(info, infoRequest)
		
		// Remove from active requests
		for (index, someRequest) in activeRequests.enumerated() {
			if someRequest === infoRequest {
				activeRequests.remove(at: index)
				break
			}
		}
		
		// Start the next request in queue going
		performNextPendingRequest()
	}
	
	var activeRetrievals = [ResourceInfoRetrievalStage]()
	var pendingRetrievals = [ResourceInfoRetrievalStage]()
	//let executionCustomizer = GCDExecutionCustomizer<ResourceInfoRetrievalStage>()
	
	fileprivate func performRetrieval(_ stage: ResourceInfoRetrievalStage) {
		stage.execute { useResult in
			do {
				let result = try useResult()
			}
			catch {
				// ERROR
			}
		}
	}
	
	fileprivate func performRequest(_ infoRequest: PageInfoRequest) {
		activeRequests.append(infoRequest)
		
		// An Alamofire serializer to perform the parsing etc on the request’s background queue.
		let serializer = DataResponseSerializer<PageInfo> { URLRequest, response, data, error in
			guard error == nil else { return .failure(error!) }
			
			if let response = response {
				let requestedURL = infoRequest.URL
				let MIMEType = MIMETypeString(response.mimeType)
				let baseContentType: BaseContentType = MIMEType?.baseContentType ?? .unknown
				
				let byteCount: Int?
				let contentInfo: PageContentInfo?
				if let data = data , infoRequest.includingContent {
					byteCount = data.count
					contentInfo = PageContentInfo(data: data, localURL: requestedURL)
				}
				else {
					byteCount = nil
					contentInfo = nil
				}
				
				let info = PageInfo(requestedURL: requestedURL, finalURL: response.url, statusCode: response.statusCode, baseContentType: baseContentType, MIMEType: MIMEType, byteCount: byteCount, contentInfo: contentInfo)
				
				return .success(info)
			}
			else {
				let error = AFError.responseSerializationFailed(reason: .inputDataNil)
				return .failure(error)
			}
		}
		
		// Perform the request
		let requestedURL = infoRequest.URL
		infoRequest.request = requestManager
			.request(requestedURL, method: infoRequest.method)
			.response(responseSerializer: serializer, completionHandler: { response in
				if case let .success(info) = response.result {
					self.activeRequestDidComplete(infoRequest, withInfo: info)
				}
		})
	}
	
	func cancelAll(_ clearAll: Bool = true) {
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
			pendingRequests.insert(contentsOf: activeRequests, at: 0)
		}
		
		activeRequests.removeAll()
	}
}

