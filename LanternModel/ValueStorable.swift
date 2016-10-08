//
//	ValueStorable.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 26/07/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol ValueStorable {
	subscript(key: String) -> Any? { get set }
}

internal protocol ValueStorableUpdater {
	init?(fromStorable storable: ValueStorable)
	
	func updateStorable(_ storable: inout ValueStorable)
}



struct RecordJSON: ValueStorable {
	typealias Dictionary = [String: Any]
	var dictionary: Dictionary
	
	subscript(key: String) -> Any? {
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
