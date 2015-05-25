//
//  Site.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 30/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import CloudKit


private enum Error: Int {
	case NameIsEmpty = 10
	
	case HomePageURLIsEmpty = 20
	case HomePageURLIsInvalid
	
	static let domain = "HoverlyticsApp.SiteSettingsViewController.errorDomain"
	
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
	public let name: String
	public let homePageURL: NSURL
	
	static let currentVersion: UInt = 1
	
	public init(name: String, homePageURL: NSURL) {
		self.version = SiteValues.currentVersion
		self.name = name
		self.homePageURL = homePageURL
	}
}

public func ==(lhs: SiteValues, rhs: SiteValues) -> Bool {
	return
		lhs.name == rhs.name &&
		lhs.homePageURL == rhs.homePageURL
}

extension SiteValues {
	private init(fromStoredValues values: ValueStoring) {
		if let versionNumber = values["version"] as? NSNumber {
			version = UInt(versionNumber.unsignedIntegerValue)
		}
		else {
			version = SiteValues.currentVersion
		}
		name = values["name"] as! String
		homePageURL = NSURL(string: values["homePageURL"] as! String)!
	}
	
	private func updateStoredValues(var values: ValueStoring) -> ValueStoring {
		values["version"] = version
		values["name"] = name
		values["homePageURL"] = homePageURL.absoluteString!
		
		return values
	}
}

extension SiteValues {
	init(fromRecord record: CKRecord) {
		self.init(fromStoredValues: record.values)
		/*
		if let versionNumber = record.objectForKey("version") as? NSNumber {
			version = UInt(versionNumber.unsignedIntegerValue)
		}
		else {
			version = SiteValues.currentVersion
		}
		name = record.objectForKey("name") as! String
		homePageURL = NSURL(string: record.objectForKey("homePageURL") as! String)!
		*/
	}
	
	func updateValuesInRecord(record: CKRecord) {
		var values = record.values
		updateStoredValues(values)
	}
	
	func createRecord() -> CKRecord {
		let record = CKRecord(recordType: RecordType.Site.identifier)
		updateValuesInRecord(record);
		return record
	}
}

extension SiteValues {
	init(fromJSON JSON: [String: AnyObject]) {
		let JSONValues = RecordJSON(dictionary: JSON as! RecordJSON.Dictionary)
		self.init(fromStoredValues: JSONValues)
	}
	
	func createJSON() -> [String: AnyObject] {
		let JSONValues = updateStoredValues(RecordJSON()) as! RecordJSON
		return JSONValues.dictionary
	}
}


public class Site {
	var record: CKRecord!
	
	public internal(set) var values: SiteValues {
		didSet {
			values.updateValuesInRecord(record)
		}
	}
	
	private init(values: SiteValues, record: CKRecord) {
		self.values = values
		self.record = record
	}
	
	convenience init(record: CKRecord) {
		self.init(values: SiteValues(fromRecord: record), record: record)
	}
	
	convenience init(values: SiteValues) {
		self.init(values: values, record: values.createRecord())
	}
	
	public var name: String { return values.name }
	public var homePageURL: NSURL { return values.homePageURL }
	
	public var identifier: String { return record.recordID.recordName }
	
	public internal(set) var GoogleAPIOAuth2TokenJSONString: String? {
		get {
			return record.objectForKey("GoogleAPIOAuth2TokenJSONString") as! String?
		}
		set {
			return record.setObject(newValue, forKey: "GoogleAPIOAuth2TokenJSONString")
		}
	}
}
