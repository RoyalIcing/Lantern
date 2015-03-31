//
//  MainState.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 31/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum MainStateNotification {
	case ChosenSiteDidChange
	
	private static let ChosenSiteDidChangeString = "HoverlyticsModel.MainState.ChosenSiteDidChangeNotification"
	
	public var notificationName: String {
		switch self {
		case .ChosenSiteDidChange:
			return MainStateNotification.ChosenSiteDidChangeString
		}
	}
}

/*
public enum MainStateNotification: String {
case ChosenSiteDidChange = "HoverlyticsModel.MainState.ChosenSiteDidChangeNotification"

public var notificationName: String {
return rawValue
}
}
*/

public class MainState {
	public init() {
		
	}
	
	public var chosenSite: Site! {
		didSet {
			mainQueue_notify(.ChosenSiteDidChange)
		}
	}
	
	private func mainQueue_notify(identifier: MainStateNotification, userInfo: [String:AnyObject]? = nil) {
		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(identifier.notificationName, object: self, userInfo: userInfo)
	}
}