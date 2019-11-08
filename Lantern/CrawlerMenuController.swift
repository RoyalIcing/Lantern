//
//	CrawlerMenuController.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 12/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation
import BurntCocoaUI


extension CrawlerImageDownloadChoice: UIChoiceRepresentative {
	var tag: Int? { return self.rawValue }
	
	typealias UniqueIdentifier = CrawlerImageDownloadChoice
	var uniqueIdentifier: UniqueIdentifier { return self }
}


class CrawlerMenuController: NSObject, NSUserInterfaceValidations {
	var imageDownloadMenuItemsAssistant: PlaceholderMenuItemAssistant<CrawlerImageDownloadChoice>!
	
	var crawlerPreferencesObserver: NotificationObserver<CrawlerPreferences.Notification>!
	
	init(imageDownloadPlaceholderMenuItem: NSMenuItem) {
		super.init()
		
		imageDownloadMenuItemsAssistant = PlaceholderMenuItemAssistant<CrawlerImageDownloadChoice>(placeholderMenuItem: imageDownloadPlaceholderMenuItem)
		imageDownloadMenuItemsAssistant.menuItemRepresentatives = [
			.neverDownload,
			.total1MB,
			.total10MB,
			.total100MB,
			.unlimited
		]
		imageDownloadMenuItemsAssistant.customization.actionAndTarget = { [weak self] widthChoice in
			return (action: #selector(CrawlerMenuController.changeImageDownloadChoice(_:)), target: self)
		}
//		imageDownloadMenuItemsAssistant.customization.state = { imageDownloadChoice in
//			let chosenImageDownloadChoice = CrawlerPreferences.sharedCrawlerPreferences.imageDownloadChoice
//			return (chosenImageDownloadChoice == imageDownloadChoice) ? NSOnState : NSOffState
//		}
		imageDownloadMenuItemsAssistant.customization.additionalSetUp = { imageDownloadChoice, menuItem in
			let chosenImageDownloadChoice = CrawlerPreferences.shared.imageDownloadChoice
			menuItem.state = (chosenImageDownloadChoice == imageDownloadChoice) ? NSControl.StateValue.on : NSControl.StateValue.off
		}
		
		updateImageDownloadMenu()
		
		startObservingCrawlerPreferences()
	}
	
	deinit {
		stopObservingCrawlerPreferences()
	}
	
	func updateImageDownloadMenu() {
		imageDownloadMenuItemsAssistant?.update()
	}
	
	func startObservingCrawlerPreferences() {
		crawlerPreferencesObserver = NotificationObserver<CrawlerPreferences.Notification>(object: CrawlerPreferences.shared)
		
		crawlerPreferencesObserver.observe(.ImageDownloadChoiceDidChange) { notification in
			self.updateImageDownloadMenu()
		}
	}
	
	func stopObservingCrawlerPreferences() {
		crawlerPreferencesObserver.stopObserving()
		crawlerPreferencesObserver = nil
	}
	
	@IBAction func changeImageDownloadChoice(_ sender: AnyObject?) {
		if let
			menuItem = sender as? NSMenuItem,
			let imageDownloadChoice = imageDownloadMenuItemsAssistant.itemRepresentative(for: menuItem)
		{
			CrawlerPreferences.shared.imageDownloadChoice = imageDownloadChoice
		}
	}
	
	@objc func validateUserInterfaceItem(_ anItem: NSValidatedUserInterfaceItem) -> Bool {
		return true
	}
}
