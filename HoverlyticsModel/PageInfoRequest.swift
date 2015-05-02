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
	typealias CompletionHandler = (info: PageInfo) -> Void
	
	let URL: NSURL
	let completionHandler: CompletionHandler
	
	init(URL: NSURL, completionHandler: CompletionHandler) {
		self.URL = URL
		self.completionHandler = completionHandler
	}
}

class PageInfoReference {
	let info: PageInfo
	
	init(info: PageInfo) {
		self.info = info
	}
}

class PageInfoRequestQueue {
	let maximumActiveRequests = 5
	var activeRequests = [PageInfoRequest]()
	var pendingRequests = [PageInfoRequest]()
	
	func addRequest(infoRequest: PageInfoRequest) {
		if activeRequests.count >= maximumActiveRequests {
			pendingRequests.append(infoRequest)
		}
		else {
			performRequest(infoRequest)
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
		infoRequest.completionHandler(info: info)
		
		for (index, someRequest) in enumerate(activeRequests) {
			if someRequest === infoRequest {
				activeRequests.removeAtIndex(index)
				break
			}
		}
		
		performNextPendingRequest()
	}
	
	private func performRequest(infoRequest: PageInfoRequest) {
		activeRequests.append(infoRequest)
		
		let serializer: Alamofire.Request.Serializer = { URLRequest, response, data in
			if
				let response = response,
				let data = data,
				let requestedURL = URLRequest.URL
			{
				let MIMEType = MIMETypeString(response.MIMEType)
				let baseContentType: BaseContentType = MIMEType?.baseContentType ?? .Unknown
				
				let contentInfo = PageContentInfo(data: data, localURL: requestedURL)
				
				var info = PageInfo(requestedURL: requestedURL, finalURL: response.URL, statusCode: response.statusCode, baseContentType: baseContentType, MIMEType: MIMEType, bytes: data.length, contentInfo: contentInfo)
				
				return (PageInfoReference(info: info), nil)
			}
			else {
				return (nil, nil)
			}
		}
		
		let requestedURL = infoRequest.URL
		Alamofire
			.request(.GET, requestedURL)
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
}

