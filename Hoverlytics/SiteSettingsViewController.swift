//
//  SiteSettingsViewController.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 30/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import HoverlyticsModel


class SiteSettingsViewController: NSViewController, NSPopoverDelegate {
	
	var modelManager: ModelManager!
	var site: Site!
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
	
	@IBAction func createSite(sender: NSButton) {
		let (siteValues, error) = copySiteValuesFromUI()
		if let siteValues = siteValues {
			modelManager.createSiteWithValues(siteValues)
			self.dismissController(nil)
			prepareForReuse()
		}
		else if let error = error {
			NSApplication.sharedApplication().presentError(error, modalForWindow: self.view.window!, delegate: nil, didPresentSelector: nil, contextInfo: nil)
		}
	}
	
	@IBAction func removeSite(sender: NSButton) {
		modelManager.removeSite(site)
	}
	
	func updateUIWithSiteValues(siteValues: SiteValues) {
		// Make sure view has loaded
		let view = self.view
		
		nameField.stringValue = siteValues.name
		homePageURLField.stringValue = siteValues.homePageURL.absoluteString!
	}
	
	func copySiteValuesFromUI() -> (SiteValues?, NSError?) {
		// Make sure view has loaded
		let view = self.view
		
		let errorDomain = "SiteSettingsViewController.validationErrorDomain"
		
		let name = nameField.stringValue
		let validatedName = ValidationError.validateString(name, identifier: "Name")
		if let error = validatedName.error {
			return (nil, error)
		}
		/*if let error = ValueValidation.InputtedString(name).validateReturningCocoaError {
			return (nil, error)
		}*/
		
		let homePageURLString = homePageURLField.stringValue
		/*if let error = ValueValidation.InputtedURLString(name).validateReturningCocoaError {
			return (nil, error)
		}*/
		let validatedHomePageURL = ValidationError.validateURLString(homePageURLString, identifier: "Home Page URL")
		if let error = validatedHomePageURL.error {
			return (nil, error)
		}
		let homePageURL = validatedHomePageURL.URL!
		
		let siteValues = SiteValues(name: name, homePageURL: homePageURL)
		return (siteValues, nil)
	}
	
	// MARK NSPopoverDelegate
	
	func popoverWillClose(notification: NSNotification) {
		willClose?(viewController: self)
	}
}
