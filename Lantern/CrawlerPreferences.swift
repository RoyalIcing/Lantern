//
//	CrawlerPreferences.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 12/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation


private func bytesForMegabytes(_ MB: UInt) -> UInt {
	return MB * 1024 * 1024
}


enum CrawlerImageDownloadChoice: Int {
	case neverDownload = 0
	case total1MB = 1
	case total10MB = 10
	case total100MB = 100
	case unlimited = -1
	
	var maximumByteCount: UInt? {
		switch self {
		case .neverDownload:
			return 0
		case .total1MB:
			return bytesForMegabytes(1)
		case .total10MB:
			return bytesForMegabytes(10)
		case .total100MB:
			return bytesForMegabytes(100)
		case .unlimited:
			return nil
		}
	}
	
	var title: String {
		switch self {
		case .neverDownload:
			return "Never Download"
		case .total1MB:
			return "Total 1MB"
		case .total10MB:
			return "Total 10MB"
		case .total100MB:
			return "Total 100MB"
		case .unlimited:
			return "Unlimited"
		}
	}
}

extension CrawlerImageDownloadChoice: UserDefaultsChoiceRepresentable {
	static var identifier = "crawlerPreferences.imageDownloadChoice"
	static var defaultValue: CrawlerImageDownloadChoice = .total10MB
}


private var ud = UserDefaults.standard


class CrawlerPreferences {
	enum Notification: String {
		case ImageDownloadChoiceDidChange = "CrawlerPreferences.ImageDownloadChoiceDidChange"
	}
	
	func notify(_ identifier: Notification, userInfo: [String:AnyObject]? = nil) {
		NotificationCenter.default.postNotification(identifier, object: self, userInfo: userInfo)
	}
	
	var imageDownloadChoice: CrawlerImageDownloadChoice = .total10MB {
		didSet {
			ud.setChoice(imageDownloadChoice)
			
			notify(.ImageDownloadChoiceDidChange)
		}
	}
	
	func updateFromDefaults() {
		imageDownloadChoice = ud.choice(CrawlerImageDownloadChoice)
	}
	
	init() {
		updateFromDefaults()
	}
	
	static var sharedCrawlerPreferences = CrawlerPreferences()
}
