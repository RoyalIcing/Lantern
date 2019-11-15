//
//	SiteSettingsViewController.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 30/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import LanternModel


class SiteSettingsViewController: NSViewController {
	
	var modelManager: ModelManager!
	var mainState: MainState!
	
	// MARK: Outlets
	@IBOutlet var homePageURLField: NSTextField!
	@IBOutlet var nameField: NSTextField!
	@IBOutlet var saveInFavoritesButton: NSButton! {
		didSet {
			saveInFavoritesButton.target = self
			saveInFavoritesButton.action = #selector(toggleSaveInFavorites(_:))
		}
	}
	
	// MARK: Callbacks
	var favoriteNameForURL: ((_ url: URL) -> String?)?
	var onSaveSite: ((_ viewController: SiteSettingsViewController) -> ())?

	// MARK: Init
	override func viewDidLoad() {
		super.viewDidLoad()
		
		homePageURLField.delegate = self
	}
	
	func prepareForReuse() {
		homePageURLField.stringValue = ""
		nameField.stringValue = ""
	}
	
	// MARK: -
	
	var editingFavorite = false
	
	func editFavorite(url: URL, name: String) {
		self.updateUI(url: url, favoriteName: name, editingFavorite: true)
	}
	
	func editVisited(url: URL) {
		self.updateUI(url: url)
	}
	
	func reset() {
		self.updateUI()
	}
	
	private func updateUI(url: URL? = nil, favoriteName: String? = nil, editingFavorite: Bool = false) {
		// Make sure view has loaded
		_ = self.view
		
		let urlString = url?.absoluteString ?? ""
		var name = ""
		self.editingFavorite = false
		
		if let favoriteName = favoriteName {
			name = favoriteName
			self.editingFavorite = editingFavorite
		}
		
		homePageURLField.stringValue = urlString
		saveInFavoritesButton.state = editingFavorite ? NSControl.StateValue.on : NSControl.StateValue.off
		nameField.isEnabled = editingFavorite
		nameField.stringValue = name
	}
	
	struct Output {
		var siteValues: SiteValues
		var saveInFavorites: Bool
	}
	
	func read(siteUUID: UUID? = nil) throws -> Output? {
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
		
		let url: URL
		do {
			url = try ValidationError.validate(urlString: homePageURLField.stringValue, identifier: "Primary URL")
		}
		catch let error as ValidationError {
			switch (saveInFavorites, error) {
			case (false, ValidationError.stringIsEmpty):
				return nil
			default:
				throw error
			}
		}
		
		let siteValues = SiteValues(name: name, homePageURL: url, UUID: siteUUID ?? UUID())
		
		return Output(siteValues: siteValues, saveInFavorites: saveInFavorites)
	}
	
	// MARK: - Actions
	
	@IBAction func createSite(_ sender: NSButton) {
		onSaveSite?(self)
	}
	
	@IBAction func toggleSaveInFavorites(_ sender: NSButton) {
		let hasFavorite = sender.state == NSControl.StateValue.on
		nameField.isEnabled = hasFavorite
	}
}

// MARK: -
	
extension SiteSettingsViewController : NSTextFieldDelegate { // MARK: NSTextFieldDelegate
	func controlTextDidChange(_ notification: Notification) {
		guard !editingFavorite else {
			return
		}
		
		guard homePageURLField === (notification.object as! NSTextField) else {
			return
		}
		
		guard let url = try? ValidationError.validate(urlString: homePageURLField.stringValue, identifier: "Primary URL") else {
			return
		}
		
		guard url.absoluteString == homePageURLField.stringValue else {
			return
		}
		
		guard let favoriteNameForURL = self.favoriteNameForURL else {
			return
		}
		
		if let name = favoriteNameForURL(url) {
			self.updateUI(url: url, favoriteName: name)
		} else {
			self.updateUI(url: url)
		}
	}
}
	
extension SiteSettingsViewController : NSPopoverDelegate { // MARK: NSPopoverDelegate
	func popoverWillClose(_ notification: Notification) {
		onSaveSite?(self)
	}
}
