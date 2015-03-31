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
	
	@IBAction func removeSite(sender: NSButton) {
		modelManager.removeSite(site)
	}
	
	func copySiteValuesFromUI() -> (SiteValues?, NSError?) {
		let whitespaceCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
		
		let name = nameField.stringValue
		if let error = ValueValidation.InputtedString(name).validateReturningCocoaError {
			return (nil, error)
		}
		
		let homePageURLString = homePageURLField.stringValue
		/*if let error = ValueValidation.InputtedURLString(name).validateReturningCocoaError {
			return (nil, error)
		}*/
		let validatedHomePageURL = ValueValidation.validateURLString(homePageURLString)
		if let error = validatedHomePageURL.error {
			return (nil, error)
		}
		let homePageURL = validatedHomePageURL.URL!
		
		let siteValues = SiteValues(name: name, homePageURL: homePageURL)
		return (siteValues, nil)
	}
}
