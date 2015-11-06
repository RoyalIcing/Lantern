//
//  BrowserState.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 11/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation


enum BrowserWidthChoice: Int {
	case SlimMobile = 1
	case MediumMobile
	case MediumTabletPortrait
	case MediumTabletLandscape
	case FullWidth
	
	var value: CGFloat? {
		switch self {
		case .SlimMobile:
			return 320.0
		case .MediumMobile:
			return 480.0
		case .MediumTabletPortrait:
			return 768.0
		case .MediumTabletLandscape:
			return 1024.0
		case .FullWidth:
			return nil
		}
	}
	
	var title: String {
		switch self {
		case .SlimMobile:
			return "Slim Mobile (iPhone 4)"
		case .MediumMobile:
			return "Medium Mobile (iPhone 6)"
		case .MediumTabletPortrait:
			return "Medium Tablet Portrait (iPad)"
		case .MediumTabletLandscape:
			return "Medium Tablet Landscape (iPad)"
		case .FullWidth:
			return "Full Width"
		}
	}
}

extension BrowserWidthChoice: UserDefaultsChoiceRepresentable {
	static var identifier = "browserPreferences.widthChoice"
	static var defaultValue: BrowserWidthChoice = .FullWidth
}


private var ud = NSUserDefaults.standardUserDefaults()


class BrowserPreferences {
	enum Notification: String {
		case WidthChoiceDidChange = "BrowserPreferences.WidthChoiceDidChange"
	}
	
	func notify(identifier: Notification, userInfo: [String:AnyObject]? = nil) {
		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(identifier.rawValue, object: self, userInfo: userInfo)
	}
	
	var widthChoice: BrowserWidthChoice = .FullWidth {
		didSet {
			ud.setChoice(widthChoice)
			
			notify(.WidthChoiceDidChange)
		}
	}
	
	func updateFromDefaults() {
		widthChoice = ud.choice(BrowserWidthChoice)
	}
	
	init() {
		updateFromDefaults()
	}
	
	static var sharedBrowserPreferences = BrowserPreferences()
}
