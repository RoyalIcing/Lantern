//
//  ChoiceUserDefaults.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 12/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol UserDefaultsChoiceRepresentable: RawRepresentable {
	static var defaultsKey: String { get }
}


extension NSUserDefaults {
	func choiceWithFallback<T: UserDefaultsChoiceRepresentable where T.RawValue == Int>(fallbackChoice: T) -> T {
		if let value = T(rawValue: integerForKey(T.defaultsKey)) {
			return value
		}
		else {
			return fallbackChoice
		}
	}
	
	func setChoice<T: UserDefaultsChoiceRepresentable where T.RawValue == Int>(choice: T) {
		setInteger(choice.rawValue, forKey: T.defaultsKey)
	}
	
	func registerDefaultForChoice<T: UserDefaultsChoiceRepresentable where T.RawValue == Int>(defaultChoice: T) {
		registerDefaults([
			T.defaultsKey: defaultChoice.rawValue
		])
	}
}