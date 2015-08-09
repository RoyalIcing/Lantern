//
//  SiteMenuItem.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 1/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import HoverlyticsModel
import BurntCocoaUI


enum SiteMenuItem {
	case Choice(SiteChoice)
	case LoadingSavedSites
	case NoSavedSitesYet
}

extension SiteMenuItem: UIChoiceRepresentative {
	var title: String {
		switch self {
		case .Choice(let siteChoice):
			switch siteChoice {
			case .SavedSite(let site):
				return site.name
			case .Custom:
				return "Enter URL Below"
			}
		case .LoadingSavedSites:
			return "(Loading Saved Sites)"
		case .NoSavedSitesYet:
			return "(No Saved Sites Yet)"
		}
	}
	
	var tag: Int? {
		return nil
	}
	
	typealias UniqueIdentifier = String
	
	var uniqueIdentifier: UniqueIdentifier {
		switch self {
		case .Choice(let siteChoice):
			switch siteChoice {
			case .SavedSite(let site):
				return site.UUID.UUIDString
			case .Custom:
				return "Custom"
			}
		case .LoadingSavedSites:
			return "LoadingSavedSites"
		case .NoSavedSitesYet:
			return "NoSavedSitesYet"
		}
	}
}

extension SiteMenuItem: DebugPrintable {
	var debugDescription: String {
		switch self {
		case .Choice(let siteChoice):
			switch siteChoice {
			case .SavedSite(let site):
				return "\(site.name) \(site.UUID.UUIDString)"
			default:
				break
			}
		default:
			break
		}
		
		return uniqueIdentifier
	}
}
