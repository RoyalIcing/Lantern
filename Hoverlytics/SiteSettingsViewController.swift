//
//  SiteSettingsViewController.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 30/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import HoverlyticsModel


class SiteSettingsViewController: NSViewController {
	
	var modelManager: ModelManager!
	var site: Site!
	@IBOutlet var nameField: NSTextField!
	@IBOutlet var homePageURLField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
	
	@IBAction func createSite(sender: NSButton) {
		let (siteValues, error) = copySiteValuesFromUI()
		if let siteValues = siteValues {
			modelManager.createSiteWithValues(siteValues)
			self.dismissController(nil)
		}
		else if let error = error {
			NSApplication.sharedApplication().presentError(error, modalForWindow: self.view.window!, delegate: nil, didPresentSelector: nil, contextInfo: nil)
		}
	}
	
	@IBAction func removeSite(sender: NSButton) {
		modelManager.removeSite(site)
	}
	
	func updateUIWithSiteValues(siteValues: SiteValues) {
		nameField.stringValue = siteValues.name
		homePageURLField.stringValue = siteValues.homePageURL.absoluteString!
	}
	
	func copySiteValuesFromUI() -> (SiteValues?, NSError?) {
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
}
