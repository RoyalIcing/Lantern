//
//  PageMapper+UI.swift
//  Lantern
//
//  Created by Patrick Smith on 1/11/16.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa
import LanternModel


protocol PageMapperProvider {
	var pageMapper: PageMapper? { get }
	
	func clearPageMapper()
	func createPageMapper(primaryURL: URL) -> PageMapper?
}

extension NSResponder {
	var pageMapperProvider: PageMapperProvider? {
		return sequence(first: self, next: { $0.nextResponder }).reduce(PageMapperProvider?.none) {
			$0 ?? ($1 as? PageMapperProvider)
		}
	}
}
