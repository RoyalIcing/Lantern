//
//  CrawlerPreferences.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 12/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation


private func bytesForMegabytes(MB: UInt) -> UInt {
	return MB * 1024 * 1024
}


enum CrawlerImageDownloadChoice: Int {
	case NeverDownload = 0
	case Total1MB = 1
	case Total10MB = 10
	case Total100MB = 100
	case Unlimited = -1
	
	var maximumByteCount: UInt? {
		switch self {
		case .NeverDownload:
			return 0
		case .Total1MB:
			return bytesForMegabytes(1)
		case .Total10MB:
			return bytesForMegabytes(10)
		case .Total100MB:
			return bytesForMegabytes(100)
		case .Unlimited:
			return nil
		}
	}
	
	var title: String {
		switch self {
		case .NeverDownload:
			return "Never Download"
		case .Total1MB:
			return "Total 1MB"
		case .Total10MB:
			return "Total 10MB"
		case .Total100MB:
			return "Total 100MB"
		case .Unlimited:
			return "Unlimited"
		}
	}
}

extension CrawlerImageDownloadChoice: UserDefaultsChoiceRepresentable {
	static var defaultsKey = "crawlerPreferences.imageDownloadChoice"
}


private var ud = NSUserDefaults.standardUserDefaults()


class CrawlerPreferences {
	enum Notification: String {
		case ImageDownloadChoiceDidChange = "CrawlerPreferences.ImageDownloadChoiceDidChange"
	}
	
	func notify(identifier: Notification, userInfo: [String:AnyObject]? = nil) {
		NSNotificationCenter.defaultCenter().postNotification(identifier, object: self, userInfo: userInfo)
	}
	
	var imageDownloadChoice: CrawlerImageDownloadChoice = .Total10MB {
		didSet {
			ud.setIntChoice(imageDownloadChoice)
			
			notify(.ImageDownloadChoiceDidChange)
		}
	}
	
	func updateFromDefaults() {
		imageDownloadChoice = ud.intChoiceWithFallback(imageDownloadChoice)
	}
	
	init() {
		updateFromDefaults()
	}
	
	static var sharedCrawlerPreferences = CrawlerPreferences()
}
