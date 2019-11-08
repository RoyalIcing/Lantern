//
//	BrowserMenuAssistant.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 11/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation
import BurntCocoaUI


extension BrowserWidthChoice : UIChoiceRepresentative {
	var tag: Int? { return self.rawValue }
	
	typealias UniqueIdentifier = BrowserWidthChoice
	var uniqueIdentifier: UniqueIdentifier { return self }
}

extension BrowserWidthChoice : UIChoiceEnumerable {
	static var allChoices: [BrowserWidthChoice] {
		return [
			.slimMobile,
			.mediumMobile,
			.mediumTabletPortrait,
			.mediumTabletLandscape,
			.fullWidth
		]
	}
}



class BrowserMenuController: NSObject, NSUserInterfaceValidations {
	var widthMenuItemsAssistant: PlaceholderMenuItemAssistant<BrowserWidthChoice>!
	
	var browserPreferencesObserver: NotificationObserver<BrowserPreferences.Notification>!
	
	var browserPrefences: BrowserPreferences {
		return BrowserPreferences.shared
	}
	
	init(browserWidthPlaceholderMenuItem: NSMenuItem) {
		super.init()
		
		widthMenuItemsAssistant = PlaceholderMenuItemAssistant<BrowserWidthChoice>(placeholderMenuItem: browserWidthPlaceholderMenuItem)
		widthMenuItemsAssistant.menuItemRepresentatives = [
			.slimMobile,
			.mediumMobile,
			.mediumTabletPortrait,
			.mediumTabletLandscape,
			.fullWidth
		]
		widthMenuItemsAssistant.customization.actionAndTarget = { [weak self] widthChoice in
			return (action: #selector(BrowserMenuController.changeWidthChoice(_:)), target: self)
		}
//		widthMenuItemsAssistant.customization.state = { widthChoice in
//			let chosenWidthChoice = BrowserPreferences.sharedBrowserPreferences.widthChoice
//			return (chosenWidthChoice == widthChoice) ? NSOnState : NSOffState
//		}
		widthMenuItemsAssistant.customization.additionalSetUp = { widthChoice, menuItem in
			let chosenWidthChoice = BrowserPreferences.shared.widthChoice
			menuItem.state = (chosenWidthChoice == widthChoice) ? NSControl.StateValue.on : NSControl.StateValue.off
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
		browserPreferencesObserver = NotificationObserver<BrowserPreferences.Notification>(object: BrowserPreferences.shared)
		
		browserPreferencesObserver.observe(.widthChoiceDidChange) { notification in
			self.updateWidthMenu()
		}
	}
	
	func stopObservingBrowserPreferences() {
		browserPreferencesObserver.stopObserving()
		browserPreferencesObserver = nil
	}
	
	@IBAction func changeWidthChoice(_ sender: AnyObject?) {
		if let
			menuItem = sender as? NSMenuItem,
			let widthChoice = widthMenuItemsAssistant.itemRepresentative(for: menuItem)
		{
			BrowserPreferences.shared.widthChoice = widthChoice
		}
	}
	
	@objc func validateUserInterfaceItem(_ anItem: NSValidatedUserInterfaceItem) -> Bool {
		return true
	}
}
