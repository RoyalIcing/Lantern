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
	
	// MARK -
	
	func reset(url: URL? = nil, favoriteName: String? = nil) {
		// Make sure view has loaded
		_ = self.view
		
		let urlString = url?.absoluteString ?? ""
		var name = ""
		var hasFavorite = false
		
		if let favoriteName = favoriteName {
			name = favoriteName
			hasFavorite = true
		}
		
		homePageURLField.stringValue = urlString
		saveInFavoritesButton.state = hasFavorite ? NSControl.StateValue.on : NSControl.StateValue.off
		nameField.isEnabled = hasFavorite
		nameField.stringValue = name
	}
	
	struct Output {
		var siteValues: SiteValues
		var saveInFavorites: Bool
	}
	
	func read(newSiteUUID: UUID? = nil) throws -> Output? {
		// Make sure view has loaded
		_ = self.view
		
		let saveInFavorites = saveInFavoritesButton.state == NSControl.StateValue.on
		
		let name: String
		if saveInFavorites {
			name = try ValidationError.validateString(nameField.stringValue, identifier: "Name")
		}
		else {
			name = ""
		}
		
		let homePageURL: URL
		do {
			homePageURL = try ValidationError.validate(urlString: homePageURLField.stringValue, identifier: "Primary URL")
		}
		catch let error as ValidationError {
			switch (saveInFavorites, error) {
			case (false, ValidationError.stringIsEmpty):
				return nil
			default:
				throw error
			}
		}
		
		let siteValues = SiteValues(name: name, homePageURL: homePageURL, UUID: newSiteUUID ?? UUID())
		
		return Output(siteValues: siteValues, saveInFavorites: saveInFavorites)
	}
	
	@IBAction func createSite(_ sender: NSButton) {
		onSaveSite?(self)
	}
	
	@IBAction func toggleSaveInFavorites(_ sender: NSButton) {
		let hasFavorite = sender.state == NSControl.StateValue.on
		nameField.isEnabled = hasFavorite
	}
	
	// MARK NSPopoverDelegate
	
	func popoverWillClose(_ notification: Notification) {
		onSaveSite?(self)
	}
}
