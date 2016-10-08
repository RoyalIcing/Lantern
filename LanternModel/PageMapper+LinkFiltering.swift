//
//	PageMapper+LinkFiltering.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 3/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono


public enum PageLinkFilter {
	case isLinkedByURL(URL)
	case containsLinkToURL(URL)
}


extension PageMapper {
	public func copyHTMLPageURLsFilteredBy(_ linkFilter: PageLinkFilter) -> [URL] {
		let URLs = copyURLsWithBaseContentType(.localHTMLPage, withResponseType: .successful)
		
		switch linkFilter {
		case .isLinkedByURL(let linkedByURL):
			if let contentInfo = self.pageInfoForRequestedURL(linkedByURL)?.contentInfo {
				return URLs.filter { (URLToCheck) in
					return contentInfo.containsLocalPageURL(URLToCheck)
				}
			}
			else {
				return []
			}
		case .containsLinkToURL(let childURL):
			return URLs.filter { (URLToCheck) in
				if let contentInfo = self.pageInfoForRequestedURL(URLToCheck)?.contentInfo {
					return contentInfo.containsLocalPageURL(childURL)
				}
				
				return false
			}
		}
	}
}
