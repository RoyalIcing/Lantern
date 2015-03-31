//
//  Site.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 30/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import CloudKit


private enum ErrorCode: Int {
	case NameIsEmpty = 10
	
	case HomePageURLIsEmpty = 20
	case HomePageURLIsInvalid
}

private enum Error {
	case NameIsEmpty
	
	case HomePageURLIsEmpty
	case HomePageURLIsInvalid
	
	static let domain = "HoverlyticsApp.SiteSettingsViewController.errorDomain"
	
	var errorCode: Int {
		switch self {
		case NameIsEmpty:
			return ErrorCode.NameIsEmpty.rawValue
		case HomePageURLIsEmpty:
			return ErrorCode.HomePageURLIsEmpty.rawValue
		case HomePageURLIsInvalid:
			return ErrorCode.HomePageURLIsInvalid.rawValue
		}
	}
	
	var description: String {
		switch self {
		case NameIsEmpty:
			return "Please enter a name for your site"
		case HomePageURLIsEmpty:
			return "Please enter a URL for your site’s home page"
		case HomePageURLIsInvalid:
			return "Please enter a valid URL for your site’s home page"
		}
	}
	
	var cocoaError: NSError {
		let userInfo = [
			NSLocalizedDescriptionKey: self.description
		]
		return NSError(domain: Error.domain, code: self.errorCode, userInfo: userInfo)
	}
}


public struct SiteValues {
	public let name: String
	public let homePageURL: NSURL
	
	public init(name: String, homePageURL: NSURL) {
		self.name = name
		self.homePageURL = homePageURL
	}
}

extension SiteValues {
	init(fromRecord record: CKRecord) {
		name = record.objectForKey("name") as String
		homePageURL = NSURL(string: record.objectForKey("homePageURL") as String)!
	}
}


public class Site {
	public var record: CKRecord!
	
	public let values: SiteValues
	public var needsSaving: Bool = false
	
	private init(values: SiteValues, record: CKRecord?) {
		self.values = values
		
		if let record = record {
			self.record = record
		}
		else {
			let record = CKRecord(recordType: RecordType.Site.identifier)
			record.setObject(values.name, forKey: "name")
			record.setObject(values.homePageURL.absoluteString!, forKey: "homePageURL")
			self.record = record
			needsSaving = true
		}
	}
	
	public convenience init(record: CKRecord) {
		self.init(values: SiteValues(fromRecord: record), record: record)
	}
	
	public convenience init(values: SiteValues) {
		self.init(values: values, record: nil)
	}
	
	public var name: String { return values.name }
	public var homePageURL: NSURL { return values.homePageURL }
}

/*
public class WebPage {
	var record: CKRecord!
	
	let URL: NSURL
}
*/
/*
class FavoritedWebPage : WebPage {
	
}
*/