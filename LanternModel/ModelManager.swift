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


enum SiteListProgression : StageProtocol {
	case none
	case loadFromFile(fileURL: URL)
	case jsonData(Data)
	case json(Any)
	case sitesList(sitesList: [SiteValues], needsSaving: Bool)
	
	typealias Result = [SiteValues]
		
	enum ErrorKind : Error {
		case invalidJSON(json: Any)
	}
	
	func next() -> Deferred<SiteListProgression> {
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

public class ModelManager {
	var isAvailable = false
	
	public let errorReceiver = ErrorReceiver()
	
	fileprivate var storeDirectory: SystemDirectory
	
	fileprivate var siteListProgression: SiteListProgression
	
	public var allSites: [SiteValues]? {
		return siteListProgression.result
	}
	
	
	init() {
		siteListProgression = .none
		
		storeDirectory = SystemDirectory(pathComponents: ["v1"], inUserDirectory: .applicationSupportDirectory, errorReceiver: errorReceiver.receiveError, useBundleIdentifier: true)
		storeDirectory.useOnQueue(DispatchQueue.main) { directoryURL in
			let jsonURL = directoryURL.appendingPathComponent("sites.json")
			
			let siteListProgression = SiteListProgression.loadFromFile(fileURL: jsonURL)
			NSLog("LOADING SITES")
			siteListProgression.execute { [weak self] useResult in
				NSLog("LOADED SITES")
				guard let receiver = self else { return }
				do {
					print("Sites:")
					let sites = try useResult()
					print(sites)
					receiver.siteListProgression = .sitesList(sitesList: sites, needsSaving: false)
					receiver.notifyAllSitesDidChange()
				}
				catch let error {
					print("Error loading local sites \(error)")
				}
			}
			
			self.siteListProgression = siteListProgression
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
	
	fileprivate func mainQueue_notify(_ identifier: ModelManagerNotification, userInfo: [String:AnyObject]? = nil) {
		let nc = NotificationCenter.default
		nc.post(name: Notification.Name(rawValue: identifier.notificationName), object: self, userInfo: userInfo)
	}
	
	func notifyAllSitesDidChange() {
		self.mainQueue_notify(.allSitesDidChange)
	}
	
	open func createSiteWithValues(_ siteValues: SiteValues) {
		siteListProgression.add(siteValues)
	}
	
	open func updateSiteWithUUID(_ uuid: Foundation.UUID, withValues siteValues: SiteValues) {
		siteListProgression.update(siteValues, uuid: uuid)
	}
	
	open func removeSiteWithUUID(_ uuid: Foundation.UUID) {
		siteListProgression.remove(uuid: uuid)
	}
}
