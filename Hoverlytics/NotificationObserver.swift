//
//  NotificationObserver.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 11/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


class NotificationObserver<NotificationType: RawRepresentable where NotificationType.RawValue == String, NotificationType: Hashable> {
	let object: AnyObject
	let notificationCenter: NSNotificationCenter
	let operationQueue: NSOperationQueue
	
	var observers = [NotificationType: AnyObject]()
	
	init(object: AnyObject, notificationCenter: NSNotificationCenter, queue: NSOperationQueue) {
		self.object = object
		self.notificationCenter = notificationCenter
		self.operationQueue = queue
	}
	
	convenience init(object: AnyObject) {
		self.init(object: object, notificationCenter: NSNotificationCenter.defaultCenter(), queue: NSOperationQueue.mainQueue())
	}
	
	func addObserver(notificationIdentifier: NotificationType, block: (NSNotification!) -> Void) {
		let observer = notificationCenter.addObserverForName(notificationIdentifier.rawValue, object: object, queue: operationQueue, usingBlock: block)
		observers[notificationIdentifier] = observer
	}
	
	func removeObserver(notificationIdentifier: NotificationType) {
		if let observer: AnyObject = observers[notificationIdentifier] {
			notificationCenter.removeObserver(observer)
			observers.removeValueForKey(notificationIdentifier)
		}
	}
	
	func removeAllObservers() {
		for (notificationIdentifier, observer) in observers {
			notificationCenter.removeObserver(observer)
		}
		observers.removeAll()
	}
	
	deinit {
		removeAllObservers()
	}
}


extension NSNotificationCenter {
	func postNotification
		<NotificationType: RawRepresentable where NotificationType.RawValue == String>
		(notificationIdentifier: NotificationType, object: AnyObject, userInfo: [String:AnyObject]? = nil)
	{
		postNotificationName(notificationIdentifier.rawValue, object: object, userInfo: userInfo)
	}
}
