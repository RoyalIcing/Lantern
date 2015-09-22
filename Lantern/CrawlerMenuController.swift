//
//  CrawlerMenuController.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 12/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
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
			.NeverDownload,
			.Total1MB,
			.Total10MB,
			.Total100MB,
			.Unlimited
		]
		imageDownloadMenuItemsAssistant.customization.actionAndTarget = { [weak self] widthChoice in
			return (action: "changeImageDownloadChoice:", target: self)
		}
		imageDownloadMenuItemsAssistant.customization.state = { imageDownloadChoice in
			let chosenImageDownloadChoice = CrawlerPreferences.sharedCrawlerPreferences.imageDownloadChoice
			return (chosenImageDownloadChoice == imageDownloadChoice) ? NSOnState : NSOffState
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
		crawlerPreferencesObserver = NotificationObserver<CrawlerPreferences.Notification>(object: CrawlerPreferences.sharedCrawlerPreferences)
		
		crawlerPreferencesObserver.addObserver(.ImageDownloadChoiceDidChange) { notification in
			self.updateImageDownloadMenu()
		}
	}
	
	func stopObservingCrawlerPreferences() {
		crawlerPreferencesObserver.removeAllObservers()
		crawlerPreferencesObserver = nil
	}
	
	@IBAction func changeImageDownloadChoice(sender: AnyObject?) {
		if let
			menuItem = sender as? NSMenuItem,
			imageDownloadChoice = imageDownloadMenuItemsAssistant.itemRepresentativeForMenuItem(menuItem)
		{
			CrawlerPreferences.sharedCrawlerPreferences.imageDownloadChoice = imageDownloadChoice
		}
	}
	
	@objc func validateUserInterfaceItem(anItem: NSValidatedUserInterfaceItem) -> Bool {
		return true
	}
}
