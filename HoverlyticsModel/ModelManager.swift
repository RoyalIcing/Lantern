//
//  ModelManager.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 31/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import CloudKit


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

private struct ModelCollectionAllObjectsSubscriptions {
	var onRecordCreation: CKSubscription
	var onRecordUpdate: CKSubscription
	var onRecordDeletion: CKSubscription
	
	static var cloudSubscriptionBaseIdentifier: String = {
		let cloudSubscriptionBaseIdentifierDefaultsKey = "cloudSubscriptionBaseIdentifier"
		let ud = NSUserDefaults.standardUserDefaults()
		ud.registerDefaults([
			cloudSubscriptionBaseIdentifierDefaultsKey: NSUUID().UUIDString
		])
		return ud.stringForKey(cloudSubscriptionBaseIdentifierDefaultsKey)!
	}()
}

private extension ModelCollectionAllObjectsSubscriptions {
	init(recordType: String) {
		let predicate = NSPredicate(value: true)
		let baseIdentifier = ModelCollectionAllObjectsSubscriptions.cloudSubscriptionBaseIdentifier
		self.init(
			onRecordCreation: CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: baseIdentifier.stringByAppendingString("creation"), options: .FiresOnRecordCreation),
			onRecordUpdate: CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: baseIdentifier.stringByAppendingString("update"), options: .FiresOnRecordUpdate),
			onRecordDeletion: CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: baseIdentifier.stringByAppendingString("deletion"), options: .FiresOnRecordDeletion)
		)
	}
}


public class ModelManager {
	let container = CKContainer.hoverlyticsContainer()
	let database = CKContainer.hoverlyticsContainer().privateCloudDatabase
	//let database = container.privateCloudDatabase
	var isAvailable = false
	var ubiquityIdentityDidChangeObserver: AnyObject!
	
	public var didEncounterErrorCallback: ((error: NSError) -> Void)?
	
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
	
	private var allSitesSubscription: ModelCollectionAllObjectsSubscriptions!
	
	private func createCloudSubscriptions() {
		allSitesSubscription = ModelCollectionAllObjectsSubscriptions(recordType: RecordType.Site.identifier)
	}
	
	public func handleRemoteNotification(remoteNotificationDictionary: [NSObject: AnyObject]) {
		if let queryNotification = CKNotification(fromRemoteNotificationDictionary: remoteNotificationDictionary) as? CKQueryNotification {
			// TODO:
		}
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
	
	func updateAccountStatus() {
		container.accountStatusWithCompletionHandler { (accountStatus, error) -> Void in
			self.isAvailable = (accountStatus == .Available)
			
			if let error = error {
				self.background_didEncounterError(error)
			}
			else {
				self.updateMainProperties()
			}
		}
	}
	
	public var allSites: [Site]! = nil
	
	func notifyAllSitesDidChange() {
		self.mainQueue_notify(.AllSitesDidChange)
	}
	
	func updateAllSites(allSites: [Site]?) {
		#if DEBUG
			println("updateAllSites before \(self.allSites?.count) after \(allSites?.count)")
		#endif
		self.runOnForegroundQueue {
			self.allSites = allSites
			self.notifyAllSitesDidChange()
		}
	}
	
	func queryAllSites() {
		if isAvailable {
			let predicate = NSPredicate(value: true)
			let query = CKQuery(recordType: RecordType.Site.identifier, predicate: predicate)
			query.sortDescriptors = [
				NSSortDescriptor(key: "name", ascending: true)
			]
			database.performQuery(query, inZoneWithID: nil) { (siteRecords, error) -> Void in
				if let error = error {
					self.background_didEncounterError(error)
				}
				else if let siteRecords = siteRecords as? [CKRecord] {
					let allSites: [Site] = siteRecords.map { siteRecord in
						return Site(record: siteRecord)
					}
					self.updateAllSites(allSites)
				}
			}
		}
		else {
			self.updateAllSites(nil)
		}
	}
	
	public func createSiteWithValues(siteValues: SiteValues) {
		let site = Site(values: siteValues)
		
		let operation = CKModifyRecordsOperation(recordsToSave: [site.record], recordIDsToDelete: nil)
		operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
			//self.queryAllSites()
			//self.mainQueue_notify(.AllSitesDidChange)
		}
		database.addOperation(operation)
		
		// Immediately update the UI.
		var allSites = self.allSites
		allSites.append(site)
		updateAllSites(allSites)
	}
	
	private func saveSite(site: Site) {
		let operation = CKModifyRecordsOperation(recordsToSave: [site.record], recordIDsToDelete: nil)
		operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
			if let error = error {
				self.background_didEncounterError(error)
			}
			//self.queryAllSites()
		}
		database.addOperation(operation)
		
		notifyAllSitesDidChange()
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
	
	public func setGoogleOAuth2TokenJSONString(tokenJSONString: String, forSite site: Site) {
		site.GoogleAPIOAuth2TokenJSONString = tokenJSONString
		
		saveSite(site)
	}
	
	public func removeSite(site: Site) {
		let record = site.record
		let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record.recordID])
		operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
			if let error = error {
				self.background_didEncounterError(error)
			}
			//self.queryAllSites()
		}
		database.addOperation(operation)
		
		var allSites = self.allSites
		for (index, siteToCheck) in enumerate(allSites) {
			if site === siteToCheck {
				allSites.removeAtIndex(index)
				updateAllSites(allSites)
				break
			}
		}
	}
}
