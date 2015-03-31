//
//  ModelManager.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 31/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import CloudKit


enum RecordType {
	case Site
	
	
	private static let siteIdentifier = "Site"
	
	var identifier: String {
		switch self {
		case .Site:
			return RecordType.siteIdentifier
		}
	}
}


public enum ModelManagerNotification: String {
	case AllSitesDidChange = "HoverlyticsModel.ModelManager.AllSitesDidChangeNotification"
	
	public var notificationName: String {
		return self.rawValue
	}
}


public class ModelManager {
	let container = CKContainer.hoverlyticsContainer()
	let database = CKContainer.hoverlyticsContainer().privateCloudDatabase
	//let database = container.privateCloudDatabase
	var isAvailable = false
	var ubiquityIdentityDidChangeObserver: AnyObject!
	
	init() {
		let fm = NSFileManager.defaultManager()
		let nc = NSNotificationCenter.defaultCenter()
		let mainQueue = NSOperationQueue.mainQueue()
		ubiquityIdentityDidChangeObserver = nc.addObserverForName(NSUbiquityIdentityDidChangeNotification, object: fm, queue: mainQueue) { (note) in
			self.updateAccountStatus()
		}
		
		updateAccountStatus()
	}
	
	deinit {
		let nc = NSNotificationCenter.defaultCenter()
		nc.removeObserver(ubiquityIdentityDidChangeObserver)
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
	
	private func runOnForegroundQueue(block: () -> Void) {
		NSOperationQueue.mainQueue().addOperationWithBlock(block)
	}
	
	private func mainQueue_notify(identifier: ModelManagerNotification, userInfo: [String:AnyObject]? = nil) {
		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(identifier.notificationName, object: self, userInfo: userInfo)
	}
	
	func updateAccountStatus() {
		container.accountStatusWithCompletionHandler { (accountStatus, error) -> Void in
			self.isAvailable = (accountStatus == .Available)
			
			if let error = error {
				// TODO: error
			}
			else {
				self.updateMainProperties()
			}
		}
	}
	
	public var allSites: [Site]! = nil
	
	func queryAllSites() {
		func setAllSites(receiver: ModelManager, allSites: [Site]?) -> Void {
			receiver.runOnForegroundQueue {
				receiver.allSites = allSites
				receiver.mainQueue_notify(.AllSitesDidChange)
			}
		}
		
		if isAvailable {
			let predicate = NSPredicate(value: true)
			let query = CKQuery(recordType: RecordType.Site.identifier, predicate: predicate)
			database.performQuery(query, inZoneWithID: nil) { (siteRecords, error) -> Void in
				if let error = error {
					// TODO: error
				}
				else if let siteRecords = siteRecords as? [CKRecord] {
					let allSites: [Site] = siteRecords.map { siteRecord in
						return Site(record: siteRecord)
					}
					setAllSites(self, allSites)
				}
			}
		}
		else {
			setAllSites(self, nil)
		}
	}
	
	public func createSiteWithValues(siteValues: SiteValues) {
		let site = Site(values: siteValues)
		let operation = CKModifyRecordsOperation(recordsToSave: [site.record], recordIDsToDelete: nil)
		operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
			self.queryAllSites()
		}
		database.addOperation(operation)
	}
	
	public func removeSite(site: Site) {
		let record = site.record
		let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record.recordID])
		operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
			self.queryAllSites()
		}
		database.addOperation(operation)
	}
}