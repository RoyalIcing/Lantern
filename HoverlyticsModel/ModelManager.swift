//
//  ModelManager.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 31/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum RecordType: String {
	case Site = "Site"
	
	var identifier: String {
		return self.rawValue
	}
}


public enum ModelManagerNotification: String {
	case AllSitesDidChange = "HoverlyticsModel.ModelManager.AllSitesDidChangeNotification"
	
	public var notificationName: String {
		return self.rawValue
	}
}


public class ModelManager {
	var isAvailable = false
	
	public var didEncounterErrorCallback: ((error: NSError) -> Void)?
	
	init() {
		let fm = NSFileManager.defaultManager()
		let nc = NSNotificationCenter.defaultCenter()
		let mainQueue = NSOperationQueue.mainQueue()
	}
	
	deinit {
		let nc = NSNotificationCenter.defaultCenter()
	}
	
	public class var sharedManager: ModelManager {
		struct Helper {
			static let sharedManager = ModelManager()
		}
		return Helper.sharedManager
	}
	
	func updateMainProperties() {
		queryAllSites()
	}
	
	private func runOnForegroundQueue(currentlyOnForegroundQueue: Bool = false, block: () -> Void) {
		if currentlyOnForegroundQueue {
			block()
		}
		else {
			NSOperationQueue.mainQueue().addOperationWithBlock(block)
		}
	}
	
	private func mainQueue_notify(identifier: ModelManagerNotification, userInfo: [String:AnyObject]? = nil) {
		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(identifier.notificationName, object: self, userInfo: userInfo)
	}
	
	func didEncounterError(error: NSError) {
		didEncounterErrorCallback?(error: error)
	}
	
	private func background_didEncounterError(error: NSError) {
		self.runOnForegroundQueue {
			self.didEncounterError(error)
		}
	}
	
	public var allSites: [Site]! = nil
	
	func notifyAllSitesDidChange() {
		self.mainQueue_notify(.AllSitesDidChange)
	}
	
	func updateAllSites(allSites: [Site]?) {
		self.runOnForegroundQueue {
			self.allSites = allSites
			self.notifyAllSitesDidChange()
		}
	}
	
	func queryAllSites() {
		
	}
	
	public func createSiteWithValues(siteValues: SiteValues) {
		
	}
	
	private func saveSite(site: Site) {
		
	}
	
	public func updateSiteWithValues(site: Site, siteValues: SiteValues) {
		if site.values == siteValues {
			return
		}
		
		site.values = siteValues
		
		saveSite(site)
		
		// Just do this now to immediately update the UI.
		notifyAllSitesDidChange()
	}
	
	public func removeSite(site: Site) {
		
	}
}
