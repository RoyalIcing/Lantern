//
//  SiteSettingsViewController.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 30/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import LanternModel


class SiteSettingsViewController: NSViewController, NSPopoverDelegate {
	
	var modelManager: ModelManager!
	var mainState: MainState!
	@IBOutlet var nameField: NSTextField!
	@IBOutlet var homePageURLField: NSTextField!
	var willClose: ((viewController: SiteSettingsViewController) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
	
	func prepareForReuse() {
		nameField.stringValue = ""
		homePageURLField.stringValue = ""
	}
	
	var site: SiteValues! {
		didSet {
			updateUIWithSiteValues(site)
		}
	}
	
	@IBAction func createSite(sender: NSButton) {
		do {
			let siteValues = try copySiteValuesFromUI()
			modelManager.createSiteWithValues(siteValues)
			mainState.siteChoice = .SavedSite(siteValues)
			self.dismissController(nil)
			prepareForReuse()
		}
		catch {
			NSApplication.sharedApplication().presentError(error as NSError, modalForWindow: self.view.window!, delegate: nil, didPresentSelector: nil, contextInfo: nil)
		}
	}
	
	@IBAction func removeSite(sender: NSButton) {
		modelManager.removeSiteWithUUID(site.UUID)
		self.dismissController(nil)
		prepareForReuse()
	}
	
	func updateUIWithSiteValues(siteValues: SiteValues) {
		// Make sure view has loaded
		_ = self.view
		
		nameField.stringValue = siteValues.name
		homePageURLField.stringValue = siteValues.homePageURL.absoluteString
	}
	
	func copySiteValuesFromUI(UUID UUID: NSUUID? = nil) throws -> SiteValues {
		// Make sure view has loaded
		_ = self.view
		
		let name = try ValidationError.validateString(nameField.stringValue, identifier: "Name")
		let homePageURL = try ValidationError.validateURLString(homePageURLField.stringValue, identifier: "Home Page URL")
		
		return SiteValues(name: name, homePageURL: homePageURL, UUID: UUID ?? NSUUID())
	}
	
	// MARK NSPopoverDelegate
	
	func popoverWillClose(notification: NSNotification) {
		willClose?(viewController: self)
	}
}
