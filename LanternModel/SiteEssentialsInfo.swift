//
//	SiteEssentialsInfo.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 7/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum SiteEssentialType {
	case siteMapXML
	case robotsTxt
	case valid404Page
	//case WWWRedirecting(hasWWW: Bool)
	//case HTTPS
	//case HTTPToHTTPSRedirection
	case favIconAtRoot
	//case TouchIcon
	
	
	public enum Need {
		case required
		case recommended
		case optional
	}
	
	
	public var need: Need {
		switch self {
		case .favIconAtRoot: //, .TouchIcon:
			return .recommended
		//case .HTTPS:
		//	return .Optional
		default:
			return .required
		}
	}
}


public struct SiteEssentialInfo {
	public let type: SiteEssentialType
	
	public let wasFound: Bool?
	public let isValid: Bool?
	
	public let resourceInfos: [PageInfo]
}


open class SiteEssentialInfoRequest {
	public typealias CompletionHandler = (_ info: SiteEssentialInfo) -> Void
	
	open let type: SiteEssentialType
	open let completionHandler: CompletionHandler
	
	var resourceRequests: [String: PageInfoRequest]
	var resourceInfos: [String: PageInfo]
	
	init(type: SiteEssentialType, baseURL: URL, completionHandler: @escaping CompletionHandler) {
		self.type = type
		self.completionHandler = completionHandler
		
		resourceRequests = [String: PageInfoRequest]()
		resourceInfos = [String: PageInfo]()
		
		func addResourceRequest(pathComponent: String, identifier: String? = nil) {
			let identifier = identifier ?? pathComponent
			
			func requestCompletionHandler(_ info: PageInfo) {
				
			}
			
			#if false
				var infoRequest = PageInfoRequest(URL: baseURL.URLByAppendingPathComponent(pathComponent)) { [weak self] (resourceInfo, infoRequest) in
					self?.didCompleteResourceInfoRequest(resourceInfo, identifier: identifier)
				}
				resourceRequests[identifier] = infoRequest
			#endif
		}
		
		switch type {
		case .siteMapXML:
			addResourceRequest(pathComponent: "sitemap.xml")
		case .robotsTxt:
			addResourceRequest(pathComponent: "robots.txt")
		case .valid404Page:
			// Use UUID to create a unique request every time.
			addResourceRequest(pathComponent: UUID().uuidString, identifier: "UUID")
		case .favIconAtRoot:
			addResourceRequest(pathComponent: "favicon.ico")
		}
	}
	
	func didCompleteResourceInfoRequest(_ resourceInfo: PageInfo, identifier: String) {
		resourceInfos[identifier] = resourceInfo
	}
	
	open var currentInfo: SiteEssentialInfo {
		var finished = resourceRequests.count == resourceInfos.count
		return SiteEssentialInfo(type: type, wasFound: nil, isValid: nil, resourceInfos: [])
	}
}
