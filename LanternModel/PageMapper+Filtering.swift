//
//	PageMapper+Problems.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 28/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public extension PageMapper {
	func numberOfRequestedURLsWithBaseContentType(_ type: BaseContentType) -> Int {
		switch type {
		case .localHTMLPage:
			return requestedLocalPageURLsUnique.count
		case .image:
			return requestedImageURLsUnique.count
		case .feed:
			return requestedFeedURLsUnique.count
		default:
			return 0
		}
	}
	
	func numberOfLoadedURLsWithBaseContentType(_ baseContentType: BaseContentType, responseType: PageResponseType? = nil) -> UInt {
		if let responseType = responseType {
			return baseContentTypeToResponseTypeToURLCount[baseContentType]?[responseType] ?? 0
		}
			// Else any response type: tally them up.
		else if let responseTypeToURLCount = baseContentTypeToResponseTypeToURLCount[baseContentType] {
			return responseTypeToURLCount.reduce(UInt(0), { (totalSoFar, dictIndex) -> UInt in
				let (responseType, URLCount) = dictIndex
				return totalSoFar + URLCount
			})
		}
		else {
			return 0
		}
	}
	
	func copyURLsWithBaseContentType(_ type: BaseContentType) -> [URL] {
		switch type {
		case .localHTMLPage:
			return localPageURLsOrdered as [URL]
		case .image:
			return imageURLsOrdered as [URL]
		case .feed:
			return feedURLsOrdered as [URL]
		default:
			return []
		}
	}
	
	func copyURLsWithBaseContentType(_ type: BaseContentType, withResponseType responseType: PageResponseType) -> [URL] {
		let URLs: [URL] = copyURLsWithBaseContentType(type)
		
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
