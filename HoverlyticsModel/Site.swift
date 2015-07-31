//
//  Site.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 30/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntList


private enum Error: Int {
	case NameIsEmpty = 10
	
	case HomePageURLIsEmpty = 20
	case HomePageURLIsInvalid
	
	static let domain = "LanternApp.SiteSettingsViewController.errorDomain"
	
	var errorCode: Int {
		return rawValue
	}
	
	var description: String {
		switch self {
		case NameIsEmpty:
			return NSLocalizedString("Please enter a name for your site", comment: "Site NameIsEmpty error description")
		case HomePageURLIsEmpty:
			return NSLocalizedString("Please enter a URL for your site’s home page", comment: "Site HomePageURLIsEmpty error description")
		case HomePageURLIsInvalid:
			return NSLocalizedString("Please enter a valid URL for your site’s home page", comment: "Site HomePageURLIsInvalid error description")
		}
	}
	
	var cocoaError: NSError {
		let userInfo = [
			NSLocalizedDescriptionKey: self.description
		]
		return NSError(domain: Error.domain, code: errorCode, userInfo: userInfo)
	}
}


public struct SiteValues: Equatable {
	public let version: UInt
	public let UUID: NSUUID
	
	public let name: String
	public let homePageURL: NSURL
	
	static let currentVersion: UInt = 1
	
	public init(name: String, homePageURL: NSURL, UUID: NSUUID = NSUUID()) {
		self.version = SiteValues.currentVersion
		self.name = name
		self.homePageURL = homePageURL
		self.UUID = UUID
	}
}

public func ==(lhs: SiteValues, rhs: SiteValues) -> Bool {
	return
		lhs.name == rhs.name &&
		lhs.homePageURL == rhs.homePageURL
}

extension SiteValues {
	private init(fromStoredValues values: ValueStorable) {
		if let versionNumber = values["version"] as? NSNumber {
			version = UInt(versionNumber.unsignedIntegerValue)
		}
		else {
			version = SiteValues.currentVersion
		}
		name = values["name"] as! String
		homePageURL = NSURL(string: values["homePageURL"] as! String)!
		UUID = NSUUID(UUIDString: values["UUID"] as! String)!
	}
	
	private func updateStoredValues(var values: ValueStorable) -> ValueStorable {
		values["version"] = version
		values["name"] = name
		values["homePageURL"] = homePageURL.absoluteString!
		
		return values
	}
}

extension SiteValues {
	init(fromJSON JSON: [String: AnyObject]) {
		let JSONValues = RecordJSON(dictionary: JSON)
		self.init(fromStoredValues: JSONValues)
	}
	
	func createJSON() -> [String: AnyObject] {
		let JSONValues = updateStoredValues(RecordJSON()) as! RecordJSON
		return JSONValues.dictionary
	}
}

extension SiteValues: JSONTransformable {
	public init?(fromJSON JSON: AnyObject) {
		if let JSON = JSON as? [String: AnyObject] {
			self.init(fromJSON: JSON)
		}
		else {
			//self.init(values: values)
			return nil
		}
	}
	
	public func toJSON() -> AnyObject {
		return createJSON()
	}
}


public class Site {
	public internal(set) var values: SiteValues
	
	init(values: SiteValues) {
		self.values = values
	}
	
	public var name: String { return values.name }
	public var homePageURL: NSURL { return values.homePageURL }
	
	public var identifier: String { return values.UUID.UUIDString }
}
