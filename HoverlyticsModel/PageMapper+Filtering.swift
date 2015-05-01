//
//  PageMapper+Problems.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public extension PageMapper {
	public func numberOfRequestedURLsWithBaseContentType(type: BaseContentType) -> Int {
		switch type {
		case .LocalHTMLPage:
			return requestedLocalPageURLsUnique.count
		case .Image:
			return requestedImageURLsUnique.count
		case .Feed:
			return requestedFeedURLsUnique.count
		default:
			return 0
		}
	}
	
	public func numberOfLoadedURLsWithBaseContentType(baseContentType: BaseContentType, responseType: PageResponseType? = nil) -> UInt {
		if let responseType = responseType {
			return baseContentTypeToResponseTypeToURLCount[baseContentType]?[responseType] ?? 0
		}
			// Else any response type: tally them up.
		else if let responseTypeToURLCount = baseContentTypeToResponseTypeToURLCount[baseContentType] {
			return reduce(responseTypeToURLCount, UInt(0), { (totalSoFar, dictIndex) -> UInt in
				let (responseType, URLCount) = dictIndex
				return totalSoFar + URLCount
			})
		}
		else {
			return 0
		}
	}
	
	public func copyURLsWithBaseContentType(type: BaseContentType) -> [NSURL] {
		switch type {
		case .LocalHTMLPage:
			return localPageURLsOrdered
		case .Image:
			return imageURLsOrdered
		case .Feed:
			return feedURLsOrdered
		default:
			return []
		}
	}
	
	public func copyURLsWithBaseContentType(type: BaseContentType, withResponseType responseType: PageResponseType) -> [NSURL] {
		var URLs: [NSURL] = copyURLsWithBaseContentType(type)
		
		return URLs.filter { (URL) in
			if
				let pageInfo = self.loadedURLToPageInfo[URL]
			{
				let responseTypeToCheck = PageResponseType(statusCode: pageInfo.statusCode)
				return responseTypeToCheck == responseType
			}
			
			return false
		}
	}
}
