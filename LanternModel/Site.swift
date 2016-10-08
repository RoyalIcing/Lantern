//
//	Site.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 30/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


private enum Error: Int {
	case nameIsEmpty = 10
	
	case homePageURLIsEmpty = 20
	case homePageURLIsInvalid
	
	static let domain = "LanternApp.SiteSettingsViewController.errorDomain"
	
	var errorCode: Int {
		return rawValue
	}
	
	var description: String {
		switch self {
		case .nameIsEmpty:
			return NSLocalizedString("Please enter a name for your site", comment: "Site NameIsEmpty error description")
		case .homePageURLIsEmpty:
			return NSLocalizedString("Please enter a URL for your site’s home page", comment: "Site HomePageURLIsEmpty error description")
		case .homePageURLIsInvalid:
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
	public let UUID: Foundation.UUID
	
	public let name: String
	public let homePageURL: URL
	
	public init(name: String, homePageURL: URL, UUID: Foundation.UUID = Foundation.UUID()) {
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
	fileprivate init(fromStoredValues values: ValueStorable) {
		name = values["name"] as! String
		homePageURL = URL(string: values["homePageURL"] as! String)!
		UUID = Foundation.UUID(uuidString: values["UUID"] as! String)!
	}
	
	fileprivate func updateStoredValues(_ values: ValueStorable) -> ValueStorable {
		var values = values
		values["name"] = name as AnyObject?
		values["homePageURL"] = homePageURL.absoluteString as AnyObject?
		values["UUID"] = UUID.uuidString as AnyObject?
		
		return values
	}
}

extension SiteValues {
	init(fromJSON json: [String: Any]) {
		let jsonValues = RecordJSON(dictionary: json)
		self.init(fromStoredValues: jsonValues)
	}
	
	func createJSON() -> [String: Any] {
		let jsonValues = updateStoredValues(RecordJSON()) as! RecordJSON
		return jsonValues.dictionary
	}
}
