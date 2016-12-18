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
	var willClose: ((_ viewController: SiteSettingsViewController) -> Void)?

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
	
	@IBAction func createSite(_ sender: NSButton) {
		do {
			let siteValues = try copySiteValuesFromUI()
			modelManager.createSiteWithValues(siteValues)
			mainState.siteChoice = .savedSite(siteValues)
			self.dismiss(nil)
			prepareForReuse()
		}
		catch {
			NSApplication.shared().presentError(error as NSError, modalFor: self.view.window!, delegate: nil, didPresent: nil, contextInfo: nil)
		}
	}
	
	@IBAction func removeSite(_ sender: NSButton) {
		modelManager.removeSiteWithUUID(site.UUID)
		self.dismiss(nil)
		prepareForReuse()
	}
	
	func updateUIWithSiteValues(_ siteValues: SiteValues) {
		// Make sure view has loaded
		_ = self.view
		
		nameField.stringValue = siteValues.name
		homePageURLField.stringValue = siteValues.homePageURL.absoluteString
	}
	
	func copySiteValuesFromUI(uuid: Foundation.UUID? = nil) throws -> SiteValues {
		// Make sure view has loaded
		_ = self.view
		
		let name = try ValidationError.validateString(nameField.stringValue, identifier: "Name")
		let homePageURL = try ValidationError.validateURLString(homePageURLField.stringValue, identifier: "Home Page URL")
		
		return SiteValues(name: name, homePageURL: homePageURL, UUID: uuid ?? Foundation.UUID())
	}
	
	// MARK NSPopoverDelegate
	
	func popoverWillClose(_ notification: Notification) {
		willClose?(self)
	}
}
