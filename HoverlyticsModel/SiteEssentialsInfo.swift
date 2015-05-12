//
//  SiteEssentialsInfo.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 7/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum SiteEssentialType {
	case SiteMapXML
	case RobotsTxt
	case Valid404Page
	//case WWWRedirecting(hasWWW: Bool)
	//case HTTPS
	//case HTTPToHTTPSRedirection
	case FavIconAtRoot
	//case TouchIcon
	
	
	public enum Need {
		case Required
		case Recommended
		case Optional
	}
	
	
	public var need: Need {
		switch self {
		case .FavIconAtRoot: //, .TouchIcon:
			return .Recommended
		//case .HTTPS:
		//	return .Optional
		default:
			return .Required
		}
	}
}


public struct SiteEssentialInfo {
	public let type: SiteEssentialType
	
	public let wasFound: Bool?
	public let isValid: Bool?
	
	public let resourceInfos: [PageInfo]
}


public class SiteEssentialInfoRequest {
	public typealias CompletionHandler = (info: SiteEssentialInfo) -> Void
	
	public let type: SiteEssentialType
	public let completionHandler: CompletionHandler
	
	var resourceRequests: [String: PageInfoRequest]
	var resourceInfos: [String: PageInfo]
	
	init(type: SiteEssentialType, baseURL: NSURL, completionHandler: CompletionHandler) {
		self.type = type
		self.completionHandler = completionHandler
		
		resourceRequests = [String: PageInfoRequest]()
		resourceInfos = [String: PageInfo]()
		
		func addResourceRequest(#pathComponent: String, identifier: String? = nil) {
			let identifier = identifier ?? pathComponent
			
			func requestCompletionHandler(info: PageInfo) {
				
			}
			
			#if false
				var infoRequest = PageInfoRequest(URL: baseURL.URLByAppendingPathComponent(pathComponent)) { [weak self] (resourceInfo, infoRequest) in
					self?.didCompleteResourceInfoRequest(resourceInfo, identifier: identifier)
				}
				resourceRequests[identifier] = infoRequest
			#endif
		}
		
		switch type {
		case .SiteMapXML:
			addResourceRequest(pathComponent: "sitemap.xml")
		case .RobotsTxt:
			addResourceRequest(pathComponent: "robots.txt")
		case .Valid404Page:
			// Use UUID to create a unique request every time.
			addResourceRequest(pathComponent: NSUUID().UUIDString, identifier: "UUID")
		case .FavIconAtRoot:
			addResourceRequest(pathComponent: "favicon.ico")
		}
	}
	
	func didCompleteResourceInfoRequest(resourceInfo: PageInfo, identifier: String) {
		resourceInfos[identifier] = resourceInfo
	}
	
	public var currentInfo: SiteEssentialInfo {
		var finished = resourceRequests.count == resourceInfos.count
		return SiteEssentialInfo(type: type, wasFound: nil, isValid: nil, resourceInfos: [])
	}
}
