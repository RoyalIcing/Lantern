//
//	SiteSettingsViewController.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 30/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import LanternModel


class SiteSettingsViewController: NSViewController, NSPopoverDelegate {
	
	var modelManager: ModelManager!
	var mainState: MainState!
	@IBOutlet var nameField: NSTextField!
	@IBOutlet var homePageURLField: NSTextField!
	@IBOutlet var saveInFavoritesButton: NSButton! {
		didSet {
			saveInFavoritesButton.target = self
			saveInFavoritesButton.action = #selector(toggleSaveInFavorites(_:))
		}
	}
	var onSaveSite: ((_ viewController: SiteSettingsViewController) -> ())?

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
	}
	
	func prepareForReuse() {
		nameField.stringValue = ""
		homePageURLField.stringValue = ""
	}
	
	var state: (url: URL, favoriteName: (String)?)? {
		didSet {
			// Make sure view has loaded
			_ = self.view
			
			var urlString = ""
			var name = ""
			var hasFavorite = false
			
			if let state = state {
				urlString = state.url.absoluteString
				if let favoriteName = state.favoriteName {
					name = favoriteName
					hasFavorite = true
				}
			}
			
			homePageURLField.stringValue = urlString
			saveInFavoritesButton.state = hasFavorite ? NSControl.StateValue.on : NSControl.StateValue.off
			nameField.isEnabled = hasFavorite
			nameField.stringValue = name
		}
	}
	
	@IBAction func createSite(_ sender: NSButton) {
		onSaveSite?(self)
	}
	
	@IBAction func toggleSaveInFavorites(_ sender: NSButton) {
		let hasFavorite = sender.state == NSControl.StateValue.on
		nameField.isEnabled = hasFavorite
	}
	
	func copySiteValuesFromUI(uuid: Foundation.UUID? = nil) throws -> (siteValues: SiteValues, saveInFavorites: Bool)? {
		// Make sure view has loaded
		_ = self.view
		
		let siteInFavorites = saveInFavoritesButton.state == NSControl.StateValue.on
		
		let name: String
		if siteInFavorites {
			name = try ValidationError.validateString(nameField.stringValue, identifier: "Name")
		}
		else {
			name = ""
		}
		
		do {
			let homePageURL = try ValidationError.validate(urlString: homePageURLField.stringValue, identifier: "Primary URL")
			let siteValues = SiteValues(name: name, homePageURL: homePageURL, UUID: uuid ?? UUID())
			
			return (siteValues, siteInFavorites)
		}
		catch let error as ValidationError {
			switch (siteInFavorites, error) {
			case (false, ValidationError.stringIsEmpty):
				return nil
			default:
				throw error
			}
		}
	}
	
	// MARK NSPopoverDelegate
	
	func popoverWillClose(_ notification: Notification) {
		onSaveSite?(self)
	}
}
