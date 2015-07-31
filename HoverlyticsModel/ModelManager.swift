//
//  ModelManager.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 31/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation
import BurntList


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


public class ErrorReceiver {
	public var errorCallback: ((error: NSError) -> Void)?
	
	func receiveError(error: NSError) {
		errorCallback?(error: error)
	}
}


public class ModelManager {
	var isAvailable = false
	
	public let errorReceiver = ErrorReceiver()
	
	private var storeDirectory: SystemDirectory
	
	private var sitesList: ArrayList<SiteValues>?
	private var sitesListStore: ListJSONFileStore<ArrayList<SiteValues>>?
	private var sitesListObserver: ListObserverOf<SiteValues>!
	public var allSites: [SiteValues]? {
		return sitesList?.allItems
	}
	
	
	init() {
		let fm = NSFileManager.defaultManager()
		let nc = NSNotificationCenter.defaultCenter()
		let mainQueue = NSOperationQueue.mainQueue()
		
		sitesList = ArrayList(items: [SiteValues]())
		
		let listJSONTransformer = DictionaryKeyJSONTransformer(dictionaryKey: "items", objectCoercer: { (value: [AnyObject]) in
			value as NSArray
		})
		let storeOptions = ListJSONFileStoreOptions(listJSONTransformer: listJSONTransformer)
		
		storeDirectory = SystemDirectory(pathComponents: ["v1"], inUserDirectory: .ApplicationSupportDirectory, errorReceiver: errorReceiver.receiveError, useBundleIdentifier: true)
		storeDirectory.useOnQueue(dispatch_get_main_queue()) { directoryURL in
			println("\(directoryURL)")
			let JSONURL = directoryURL.URLByAppendingPathComponent("sites.json")
			
			let store = ListJSONFileStore(creatingList: { items in
				return ArrayList<SiteValues>(items: items)
				}, loadedFromURL: JSONURL, options: storeOptions)
			store.ensureLoaded{ (list, error) in
				if let list = list {
					list.addObserver(self.sitesListObserver)
					self.sitesList = list
					self.notifyAllSitesDidChange()
				}
			}
			
			self.sitesListStore = store
		}
		
		sitesListObserver = ListObserverOf<SiteValues> { [unowned self] changes in
			self.notifyAllSitesDidChange()
		}

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
	
	func onSystemDirectoryError(error: NSError) {
		
	}
	
	func updateMainProperties() {
		
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
	
	func notifyAllSitesDidChange() {
		self.mainQueue_notify(.AllSitesDidChange)
	}
	
	public func createSiteWithValues(siteValues: SiteValues) {
		sitesList?.appendItems([siteValues])
	}
	
	private var sitesListEditableAssistant: EditableListFinderAssistant<ArrayList<SiteValues>, PrimaryIndexIterativeFinder<Int, SiteValues, NSUUID>>? {
		if let sitesList = sitesList {
			let UUIDExtractor = ItemValueExtractorOf { (item: SiteValues) in
				return item.UUID
			}
			let sitesListUUIDIndexFinder = PrimaryIndexIterativeFinder(collectionAccessor: { sitesList }, valueExtractor: UUIDExtractor)
			return EditableListFinderAssistant(list: sitesList, primaryIndexFinder: sitesListUUIDIndexFinder)
		}
		else {
			return nil
		}
	}
	
	public func updateSiteWithUUID(UUID: NSUUID, withValues siteValues: SiteValues) {
		sitesListEditableAssistant?.replaceItemWhoseValueIs(UUID, with: siteValues)
	}
	
	public func removeSiteWithUUID(UUID: NSUUID) {
		sitesListEditableAssistant?.removeItemsWithValues(Set([UUID]))
	}
}
