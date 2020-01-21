//
//	ModelManager.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 31/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation
import Syrup


enum RecordType: String {
	case Site = "Site"
	
	var identifier: String {
		return self.rawValue
	}
}


public enum ModelManagerNotification: String {
	case allSitesDidChange = "LanternModel.ModelManager.AllSitesDidChangeNotification"
	
	public var notificationName: String {
		return self.rawValue
	}
}


public final class ErrorReceiver {
	public var errorCallback: ((_ error: NSError) -> ())?
	
	func receiveError(_ error: NSError) {
		errorCallback?(error)
	}
}


enum SitesLoadingProgression : Progression {
	case none
	case loadFromFile(fileURL: URL)
	case jsonData(Data)
	case json(Any)
	case sitesList(sitesList: [SiteValues], needsSaving: Bool)
	
	typealias Result = [SiteValues]
		
	enum ErrorKind : Error {
		case invalidJSON(json: Any)
	}
	
	mutating func updateOrDeferNext() throws -> Deferred<SitesLoadingProgression>? {
		switch self {
		case let .loadFromFile(fileURL):
			do {
				let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
				self = .jsonData(data)
			}
			catch let error as NSError {
				if error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
					self = .sitesList(sitesList: [], needsSaving: false)
				}
			}
		case let .jsonData(data):
			self = try .json(JSONSerialization.jsonObject(with: data, options: []))
		case let .json(json):
			guard
				let jsonDictionary = json as? [String: Any],
				let itemsJSON = jsonDictionary["items"] as? [Any]
				else { throw ErrorKind.invalidJSON(json: json) }
			let sitesList = try itemsJSON.map { (json: Any) -> SiteValues in
				guard let jsonObject = json as? [String: Any]
					else { throw ErrorKind.invalidJSON(json: json) }
				
				return SiteValues(fromJSON: jsonObject)
			}
			
			var seenUUIDs = Set<UUID>()
			let uniqueSites = sitesList.filter { site in
				if seenUUIDs.contains(site.UUID) {
					return false
				}
				
				seenUUIDs.insert(site.UUID)
				return true
			}
			
			self = .sitesList(sitesList: uniqueSites, needsSaving: false)
		case .sitesList, .none:
			break
		}
		return nil
	}
	
	var result: Result? {
		guard case let .sitesList(result, _) = self else { return nil }
		return result
	}
	
	mutating func update(_ siteValues: SiteValues, uuid: Foundation.UUID) {
		switch self {
		case var .sitesList(sitesList, _):
			guard let index = sitesList.firstIndex(where: { $0.UUID == uuid })
				else { return }
			sitesList[index] = siteValues
			self = .sitesList(sitesList: sitesList, needsSaving: true)
		default:
			break
		}
	}
	
	mutating func addOrUpdate(_ siteValues: SiteValues) {
		let url = siteValues.homePageURL.absoluteURL
		switch self {
		case var .sitesList(sitesList, _):
			if let index = sitesList.firstIndex(where: { $0.UUID == siteValues.UUID }) {
				sitesList[index] = siteValues
			}
			else if let index = sitesList.firstIndex(where: { $0.homePageURL.absoluteURL == url }) {
				sitesList[index] = siteValues
			}
			else {
				sitesList.append(siteValues)
			}
			self = .sitesList(sitesList: sitesList, needsSaving: true)
		default:
			break
		}
	}
	
	mutating func remove(url: URL) {
		switch self {
		case var .sitesList(sitesList, _):
			sitesList = sitesList.filter{ $0.homePageURL != url }
			self = .sitesList(sitesList: sitesList, needsSaving: true)
		default:
			break
		}
	}
}

enum SitesSavingProgression : Progression {
	case saveToFile(fileURL: URL, sites: [SiteValues])
	case serializeJSON([String: Any], fileURL: URL)
	case writeData(Data, fileURL: URL)
	case savedFile(fileURL: URL)
	
	typealias Result = URL
	
	enum ErrorKind : Error {
		case invalidJSON
		case jsonSerialization(error: Error)
		case fileWriting(error: Error)
	}
	
	mutating func updateOrDeferNext() throws -> Deferred<SitesSavingProgression>? {
		switch self {
		case let .saveToFile(fileURL, sites):
			let json = [
				"items": sites.map{ $0.toJSON() }
			] as [String: [[String: Any]]]
			self = .serializeJSON(json, fileURL: fileURL)
		case let .serializeJSON(json, fileURL):
			do {
				if !JSONSerialization.isValidJSONObject(json) {
					throw ErrorKind.invalidJSON
				}
				self = try .writeData(JSONSerialization.data(withJSONObject: json), fileURL: fileURL)
			}
			catch {
				throw ErrorKind.jsonSerialization(error: error)
			}
		case let .writeData(data, fileURL):
			try data.write(to: fileURL, options: .atomic)
			self = .savedFile(fileURL: fileURL)
		case .savedFile:
			break
		}
		return nil
	}
	
	var result: Result? {
		guard case let .savedFile(fileURL) = self else { return nil }
		return fileURL
	}
}

open class ModelManager {
	var isAvailable = false
	
	public let errorReceiver = ErrorReceiver()
	
	fileprivate var storeDirectory: SystemDirectory
	fileprivate var sitesURL: URL?
	
	// Change this value, by mutating it, and it will be saved to disk
	fileprivate var sitesLoadingProgression: SitesLoadingProgression = .none {
		didSet {
			let progression = sitesLoadingProgression
			notifyAllSitesDidChange()
			
			switch progression {
			case .loadFromFile:
				progression / .utility >>= { [weak self] useResult in
					guard let receiver = self else { return }
					do {
						let sites = try useResult()
						receiver.sitesLoadingProgression = .sitesList(sitesList: sites, needsSaving: false)
					}
					catch let error {
						print("Error loading local sites \(error)")
					}
				}
			// If changed, and needs saving, then save
			case let .sitesList(sites, needsSaving):
				if needsSaving, let sitesURL = sitesURL {
					sitesSavingProgression = .saveToFile(fileURL: sitesURL, sites: sites)
				}
			default: break
			}
		}
	}
	
	fileprivate var sitesSavingProgression: SitesSavingProgression? {
		didSet(newValue) {
			guard let progression = sitesSavingProgression else { return }
			progression / .utility >>= { useResult in
				do {
					let _ = try useResult()
				}
				catch let error {
					print("Error saving local sites \(error)")
				}
			}
		}
	}
	
	public var allSites: [SiteValues]? {
		return sitesLoadingProgression.result
	}
	
	public func siteWithURL(url: URL) -> SiteValues? {
		guard let sites = allSites else { return nil }
		return sites.first{ $0.homePageURL.absoluteURL == url.absoluteURL }
	}
	
	
	init() {
		storeDirectory = SystemDirectory(pathComponents: ["v1"], inUserDirectory: .applicationSupportDirectory, errorReceiver: errorReceiver.receiveError, useBundleIdentifier: true)
		storeDirectory.useOnQueue(DispatchQueue.main) { directoryURL in
			let jsonURL = directoryURL.appendingPathComponent("sites.json")
			self.sitesURL = jsonURL
			
			self.sitesLoadingProgression = SitesLoadingProgression.loadFromFile(fileURL: jsonURL)
		}

	}
	
	open class var sharedManager: ModelManager {
		struct Helper {
			static let sharedManager = ModelManager()
		}
		return Helper.sharedManager
	}
	
	func onSystemDirectoryError(_ error: NSError) {
		
	}
	
	func updateMainProperties() {
		
	}
	
	fileprivate func mainQueue_notify(_ identifier: ModelManagerNotification, userInfo: [String: Any]? = nil) {
		let nc = NotificationCenter.default
		nc.post(name: Notification.Name(rawValue: identifier.notificationName), object: self, userInfo: userInfo)
	}
	
	func notifyAllSitesDidChange() {
		self.mainQueue_notify(.allSitesDidChange)
	}
	
	public func addOrUpdateSite(values: SiteValues) {
		//sitesLoadingProgression.update(siteValues, uuid: uuid)
		sitesLoadingProgression.addOrUpdate(values)
	}
	
	public func removeSite(url: URL) {
		sitesLoadingProgression.remove(url: url)
	}
}
