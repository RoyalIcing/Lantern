//
//	SiteMenuItem.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 1/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import LanternModel
import BurntCocoaUI


enum SiteMenuItem {
	case choice(SiteChoice)
	case loadingSavedSites
	case noSavedSitesYet
}

extension SiteMenuItem: UIChoiceRepresentative {
	var title: String {
		switch self {
		case .choice(let siteChoice):
			switch siteChoice {
			case .savedSite(let site):
				return site.name
			case .custom:
				return "Custom"
			}
		case .loadingSavedSites:
			return "(Loading Saved Sites)"
		case .noSavedSitesYet:
			return "(No Saved Sites Yet)"
		}
	}
	
	var tag: Int? {
		return nil
	}
	
	typealias UniqueIdentifier = String
	
	var uniqueIdentifier: UniqueIdentifier {
		switch self {
		case .choice(let siteChoice):
			switch siteChoice {
			case .savedSite(let site):
				let url = site.homePageURL
				guard var urlComponents = URLComponents(url: site.homePageURL, resolvingAgainstBaseURL: true) else {
					return url.absoluteString
				}
				urlComponents.fragment = nil
				return urlComponents.string ?? url.absoluteString
			case .custom:
				return "Custom"
			}
		case .loadingSavedSites:
			return "LoadingSavedSites"
		case .noSavedSitesYet:
			return "NoSavedSitesYet"
		}
	}
}

extension SiteMenuItem: CustomDebugStringConvertible {
	var debugDescription: String {
		switch self {
		case .choice(let siteChoice):
			switch siteChoice {
			case .savedSite(let site):
				return "\(site.name) \(site.UUID.uuidString)"
			default:
				break
			}
		default:
			break
		}
		
		return uniqueIdentifier
	}
}
