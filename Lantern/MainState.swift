//
//	MainState.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 31/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import LanternModel


enum SiteChoice {
	case savedSite(SiteValues)
	case custom
}

extension SiteChoice: Equatable {}

func ==(lhs: SiteChoice, rhs: SiteChoice) -> Bool {
	switch (lhs, rhs) {
	case (.custom, .custom):
		return true
	case (.savedSite(let lSite), .savedSite(let rSite)):
		return lSite.UUID == rSite.UUID
	default:
		return false
	}
}


class MainState {
	let crawlerPreferences = CrawlerPreferences.shared
	let browserPreferences = BrowserPreferences.shared
	
	var startURL: URL? {
		didSet {
			print("startURL changing \(startURL)")
			if startURL == oldValue { return }
			mainQueue_notify(Self.startURLDidChangeNotification)
		}
	}
//	var currentURL: URL?
	
	var siteChoice = SiteChoice.custom {
		didSet {
			if siteChoice == oldValue { return }
			mainQueue_notify(Self.chosenSiteDidChangeNotification)
		}
	}
	
	var chosenSite: SiteValues? {
		switch siteChoice {
		case .savedSite(let site): return site
		default: return nil
		}
	}
	
	var initialHost: String?
	
	static let startURLDidChangeNotification = Notification.Name.init("LanternModel.MainState.startURLDidChangeNotification")
	
	static let chosenSiteDidChangeNotification = Notification.Name.init("LanternModel.MainState.ChosenSiteDidChangeNotification")
	
	private func mainQueue_notify(_ name: Notification.Name, userInfo: [String: AnyObject]? = nil) {
		let nc = NotificationCenter.default
		nc.post(name: name, object: self, userInfo: userInfo)
	}
}
