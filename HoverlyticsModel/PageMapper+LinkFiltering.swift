//
//  PageMapper+LinkFiltering.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 3/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono


public enum PageLinkFilter {
	case IsLinkedByURL(NSURL)
	case ContainsLinkToURL(NSURL)
}


extension PageMapper {
	public func copyHTMLPageURLsFilteredBy(linkFilter: PageLinkFilter) -> [NSURL] {
		var URLs = copyURLsWithBaseContentType(.LocalHTMLPage, withResponseType: .Successful)
		
		switch linkFilter {
		case .IsLinkedByURL(let linkedByURL):
			if let contentInfo = self.pageInfoForRequestedURL(linkedByURL)?.contentInfo {
				return URLs.filter { (URL) in
					return contentInfo.containsLocalPageURL(URL)
				}
			}
			else {
				return []
			}
		case .ContainsLinkToURL(let childURL):
			return URLs.filter { (URL) in
				if let contentInfo = self.pageInfoForRequestedURL(childURL)?.contentInfo {
					return contentInfo.containsLocalPageURL(childURL)
				}
				
				return false
			}
		}
	}
}