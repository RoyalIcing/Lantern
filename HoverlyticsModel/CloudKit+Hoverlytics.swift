//
//  CloudKit+Hoverlytics.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 30/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import CloudKit


extension CKContainer {
	class func hoverlyticsContainer() -> CKContainer {
		return CKContainer(identifier: "iCloud.com.burntcaramel.Hoverlytics")
	}
}



protocol ValueStoring {
	subscript(key: String) -> CKRecordValue? { get set }
}

extension CKRecord {
	private struct RecordValues: ValueStoring {
		let record: CKRecord
		
		subscript(key: String) -> CKRecordValue? {
			get {
				return record.objectForKey(key) as? CKRecordValue
			}
			set {
				record.setObject(newValue, forKey: key)
			}
		}
	}
	
	var values: ValueStoring {
		return RecordValues(record: self)
	}
}

struct RecordJSON: ValueStoring {
	typealias Dictionary = [String: CKRecordValue]
	var dictionary: Dictionary
	
	subscript(key: String) -> CKRecordValue? {
		get {
			return dictionary[key]
		}
		set {
			dictionary[key] = newValue
		}
	}
}

extension RecordJSON {
	init() {
		self.init(dictionary: Dictionary())
	}
}
