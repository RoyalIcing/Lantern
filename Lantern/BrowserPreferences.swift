//
//	BrowserState.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 11/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation


enum BrowserWidthChoice: Int {
	case slimMobile = 1
	case mediumMobile
	case mediumTabletPortrait
	case mediumTabletLandscape
	case fullWidth
	
	var value: CGFloat? {
		switch self {
		case .slimMobile:
			return 320.0
		case .mediumMobile:
			return 480.0
		case .mediumTabletPortrait:
			return 768.0
		case .mediumTabletLandscape:
			return 1024.0
		case .fullWidth:
			return nil
		}
	}
	
	var title: String {
		switch self {
		case .slimMobile:
			return "Slim Mobile (iPhone 4)"
		case .mediumMobile:
			return "Medium Mobile (iPhone 6)"
		case .mediumTabletPortrait:
			return "Medium Tablet Portrait (iPad)"
		case .mediumTabletLandscape:
			return "Medium Tablet Landscape (iPad)"
		case .fullWidth:
			return "Full Width"
		}
	}
}

extension BrowserWidthChoice: UserDefaultsChoiceRepresentable {
	static var identifier = "browserPreferences.widthChoice"
	static var defaultValue: BrowserWidthChoice = .fullWidth
}


private var ud = UserDefaults.standard


class BrowserPreferences {
	enum Notification: String {
		case WidthChoiceDidChange = "BrowserPreferences.WidthChoiceDidChange"
	}
	
	func notify(_ identifier: Notification, userInfo: [String:AnyObject]? = nil) {
		let nc = NotificationCenter.default
		nc.post(name: Foundation.Notification.Name(rawValue: identifier.rawValue), object: self, userInfo: userInfo)
	}
	
	var widthChoice: BrowserWidthChoice = .fullWidth {
		didSet {
			ud.setChoice(widthChoice)
			
			notify(.WidthChoiceDidChange)
		}
	}
	
	func updateFromDefaults() {
		widthChoice = ud.choice(BrowserWidthChoice.self)
	}
	
	init() {
		updateFromDefaults()
	}
	
	static var sharedBrowserPreferences = BrowserPreferences()
}
