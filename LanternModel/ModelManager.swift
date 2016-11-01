//
//	ModelManager.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 31/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation
import Grain


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


public class ErrorReceiver {
	open var errorCallback: ((_ error: NSError) -> Void)?
	
	func receiveError(_ error: NSError) {
		errorCallback?(error)
	}
}


enum SitesLoadingProgression : StageProtocol {
	case none
	case loadFromFile(fileURL: URL)
	case jsonData(Data)
	case json(Any)
	case sitesList(sitesList: [SiteValues], needsSaving: Bool)
	
	typealias Result = [SiteValues]
		
	enum ErrorKind : Error {
		case invalidJSON(json: Any)
	}
	
	func next() -> Deferred<SitesLoadingProgression> {
		switch self {
		case let .loadFromFile(fileURL):
			return .unit{
				try .jsonData(Data(contentsOf: fileURL, options: .mappedIfSafe))
			}
		case let .jsonData(data):
			return .unit{
				try .json(JSONSerialization.jsonObject(with: data, options: []))
			}
		case let .json(json):
			return .unit{
				guard
					let jsonDictionary = json as? [String: Any],
					let itemsJSON = jsonDictionary["items"] as? [Any]
					else { throw ErrorKind.invalidJSON(json: json) }
				let sitesList = try itemsJSON.map { (json: Any) -> SiteValues in
					guard let jsonObject = json as? [String: Any]
						else { throw ErrorKind.invalidJSON(json: json) }
					
					return SiteValues(fromJSON: jsonObject)
				}
				return .sitesList(sitesList: sitesList, needsSaving: false)
			}
		case .sitesList, .none:
			completedStage(self)
		}
	}
	
	var result: Result? {
		guard case let .sitesList(result, _) = self else { return nil }
		return result
	}
	
	mutating func add(_ siteValues: SiteValues) {
		switch self {
		case var .sitesList(sitesList, _):
			sitesList.append(siteValues)
			self = .sitesList(sitesList: sitesList, needsSaving: true)
		default:
			break
		}
	}
	
	mutating func update(_ siteValues: SiteValues, uuid: Foundation.UUID) {
		switch self {
		case var .sitesList(sitesList, _):
			guard let index = sitesList.index(where: { $0.UUID == uuid })
				else { return }
			sitesList[index] = siteValues
			self = .sitesList(sitesList: sitesList, needsSaving: true)
		default:
			break
		}
	}
	
	mutating func remove(uuid: Foundation.UUID) {
		switch self {
		case var .sitesList(sitesList, _):
			guard let index = sitesList.index(where: { $0.UUID == uuid })
				else { return }
			sitesList.remove(at: index)
			self = .sitesList(sitesList: sitesList, needsSaving: true)
		default:
			break
		}
	}
}

enum SitesSavingProgression : StageProtocol {
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
	
	func next() -> Deferred<SitesSavingProgression> {
		switch self {
		case let .saveToFile(fileURL, sites):
			return .unit{
				let json = [
					"items": sites.map{ $0.toJSON() }
				] as [String: [[String: Any]]]
				return .serializeJSON(json, fileURL: fileURL)
			}
		case let .serializeJSON(json, fileURL):
			return .unit{
				do {
					if !JSONSerialization.isValidJSONObject(json) {
						throw ErrorKind.invalidJSON
					}
					return try .writeData(JSONSerialization.data(withJSONObject: json), fileURL: fileURL)
				}
				catch {
					throw ErrorKind.jsonSerialization(error: error)
				}
			}
		case let .writeData(data, fileURL):
			return .unit{
				try data.write(to: fileURL, options: .atomic)
				return .savedFile(fileURL: fileURL)
			}
		case .savedFile:
			completedStage(self)
		}
	}
	
	var result: Result? {
		guard case let .savedFile(fileURL) = self else { return nil }
		return fileURL
	}
}

public class ModelManager {
	var isAvailable = false
	
	public let errorReceiver = ErrorReceiver()
	
	fileprivate var storeDirectory: SystemDirectory
	fileprivate var sitesURL: URL?
	
	fileprivate var sitesLoadingProgression: SitesLoadingProgression = .none {
		didSet {
			let progression = sitesLoadingProgression
			notifyAllSitesDidChange()
			
			switch progression {
			case .loadFromFile:
				progression.execute { [weak self] useResult in
					guard let receiver = self else { return }
					do {
						let sites = try useResult()
						receiver.sitesLoadingProgression = .sitesList(sitesList: sites, needsSaving: false)
					}
					catch let error {
						print("Error loading local sites \(error)")
					}
				}
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
			sitesSavingProgression?.execute { useResult in
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
	
	
	init() {
		storeDirectory = SystemDirectory(pathComponents: ["v1"], inUserDirectory: .applicationSupportDirectory, errorReceiver: errorReceiver.receiveError, useBundleIdentifier: true)
		storeDirectory.useOnQueue(DispatchQueue.main) { directoryURL in
			let jsonURL = directoryURL.appendingPathComponent("sites.json")
			self.sitesURL = jsonURL
			
			self.sitesLoadingProgression = SitesLoadingProgression.loadFromFile(fileURL: jsonURL)
		}

	}
	
	public class var sharedManager: ModelManager {
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
	
	public func createSiteWithValues(_ siteValues: SiteValues) {
		sitesLoadingProgression.add(siteValues)
	}
	
	public func updateSiteWithUUID(_ uuid: Foundation.UUID, withValues siteValues: SiteValues) {
		sitesLoadingProgression.update(siteValues, uuid: uuid)
	}
	
	public func removeSiteWithUUID(_ uuid: Foundation.UUID) {
		sitesLoadingProgression.remove(uuid: uuid)
	}
}
