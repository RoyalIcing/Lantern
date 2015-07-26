//
//  BrowserMenuAssistant.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 11/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation


extension BrowserWidthChoice: MenuItemRepresentative {
	var tag: Int? { return self.rawValue }
	
	typealias UniqueIdentifier = BrowserWidthChoice
	var uniqueIdentifier: UniqueIdentifier { return self }
}


class BrowserMenuController: NSObject, NSUserInterfaceValidations {
	var widthMenuItemsAssistant: PlaceholderMenuItemAssistant<BrowserWidthChoice>!
	
	var browserPreferencesObserver: NotificationObserver<BrowserPreferences.Notification>!
	
	var browserPrefences: BrowserPreferences {
		return BrowserPreferences.sharedBrowserPreferences
	}
	
	init(browserWidthPlaceholderMenuItem: NSMenuItem) {
		super.init()
		
		widthMenuItemsAssistant = PlaceholderMenuItemAssistant<BrowserWidthChoice>(placeholderMenuItem: browserWidthPlaceholderMenuItem)
		widthMenuItemsAssistant.menuItemRepresentatives = [
			.SlimMobile,
			.MediumMobile,
			.MediumTabletPortrait,
			.MediumTabletLandscape,
			.FullWidth
		]
		widthMenuItemsAssistant.customization.actionAndTarget = { [weak self] widthChoice in
			return (action: "changeWidthChoice:", target: self)
		}
		widthMenuItemsAssistant.customization.state = { [weak self] widthChoice in
			let chosenWidthChoice = BrowserPreferences.sharedBrowserPreferences.widthChoice
			return (chosenWidthChoice == widthChoice) ? NSOnState : NSOffState
		}
		
		updateWidthMenu()
		
		startObservingBrowserPreferences()
	}
	
	deinit {
		stopObservingBrowserPreferences()
	}
	
	func updateWidthMenu() {
		widthMenuItemsAssistant.update()
	}
	
	func startObservingBrowserPreferences() {
		browserPreferencesObserver = NotificationObserver<BrowserPreferences.Notification>(object: BrowserPreferences.sharedBrowserPreferences)
		
		browserPreferencesObserver.addObserver(.WidthChoiceDidChange) { notification in
			self.updateWidthMenu()
		}
	}
	
	func stopObservingBrowserPreferences() {
		browserPreferencesObserver.removeAllObservers()
		browserPreferencesObserver = nil
	}
	
	@IBAction func changeWidthChoice(sender: AnyObject?) {
		if let
			menuItem = sender as? NSMenuItem,
			widthChoice = widthMenuItemsAssistant.itemRepresentativeForMenuItem(menuItem)
		{
			BrowserPreferences.sharedBrowserPreferences.widthChoice = widthChoice
		}
	}
	
	@objc func validateUserInterfaceItem(anItem: NSValidatedUserInterfaceItem) -> Bool {
		return true
	}
}
