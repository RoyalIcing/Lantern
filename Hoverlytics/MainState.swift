//
//  MainState.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 31/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import HoverlyticsModel


enum SiteChoice {
	case SavedSite(SiteValues)
	case Custom
}

extension SiteChoice: Equatable {}

func ==(lhs: SiteChoice, rhs: SiteChoice) -> Bool {
	switch (lhs, rhs) {
	case (.Custom, .Custom):
		return true
	case (.SavedSite(let lSite), .SavedSite(let rSite)):
		return lSite.UUID == rSite.UUID
	default:
		return false
	}
}


class MainState {
	let crawlerPreferences = CrawlerPreferences.sharedCrawlerPreferences
	let browserPreferences = BrowserPreferences.sharedBrowserPreferences
	
	var siteChoice: SiteChoice = .Custom {
		didSet {
			if siteChoice == oldValue {
				return
			}
			mainQueue_notify(.ChosenSiteDidChange)
		}
	}
	
	var chosenSite: SiteValues? {
		switch siteChoice {
		case .SavedSite(let site):
			return site
		default:
			return nil
		}
	}
	
	var initialHost: String?
	
	enum Notification: String {
		case ChosenSiteDidChange = "HoverlyticsModel.MainState.ChosenSiteDidChangeNotification"
		
		var notificationName: String {
			return self.rawValue
		}
	}
	
	func mainQueue_notify(identifier: Notification, userInfo: [String:AnyObject]? = nil) {
		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(identifier.notificationName, object: self, userInfo: userInfo)
	}
}
