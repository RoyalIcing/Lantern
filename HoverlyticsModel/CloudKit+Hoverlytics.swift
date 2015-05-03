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
