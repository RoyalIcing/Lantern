//
//  ViewController.swift
//  Hoverlytics for Mac
//
//  Created by Patrick Smith on 28/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import HoverlyticsModel


enum MainSection: Int {
	case Settings = 1
	case ViewPages = 2
}


class ViewController: NSViewController
{
	var modelManager: HoverlyticsModel.ModelManager!
	var mainState: HoverlyticsModel.MainState!
	var currentSection: MainSection?
	
	lazy var editorStoryboard: NSStoryboard = {
		NSStoryboard(name: "Editor", bundle: nil)!
	}()
	lazy var pageViewController: PageViewController = {
		self.editorStoryboard.instantiateControllerWithIdentifier("Page View Controller") as PageViewController
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//println("view did load from storyboard \(self.storyboard) parentViewController: \(self.parentViewController)")
		
		addChildViewController(pageViewController)
		let viewPageView = pageViewController.view
		fillViewWithChildView(viewPageView)
	}
	
	
	lazy var siteSettingsStoryboard = NSStoryboard(name: "SiteSettings", bundle: nil)!
	lazy var addSiteViewController: SiteSettingsViewController = {
		let vc = self.siteSettingsStoryboard.instantiateControllerWithIdentifier("Add Site View Controller") as SiteSettingsViewController
		vc.modelManager = self.modelManager
		return vc
		}()
	lazy var siteSettingsViewController: SiteSettingsViewController = {
		let vc = self.siteSettingsStoryboard.instantiateControllerWithIdentifier("Site Settings View Controller") as SiteSettingsViewController
		vc.modelManager = self.modelManager
		return vc
		}()
	
	
	@IBAction func showAddSite(button: NSButton) {
		if addSiteViewController.presentingViewController != nil {
			dismissViewController(addSiteViewController)
		}
		else {
			presentViewController(addSiteViewController, asPopoverRelativeToRect: button.bounds, ofView: button, preferredEdge: NSMaxYEdge, behavior: .Semitransient)
		}
	}
	
	
	@IBAction func showSiteSettings(button: NSButton) {
		if siteSettingsViewController.presentingViewController != nil {
			dismissViewController(siteSettingsViewController)
		}
		else {
			if let chosenSite = mainState?.chosenSite {
				siteSettingsViewController.updateUIWithSiteValues(chosenSite.values)
			}
	
			presentViewController(siteSettingsViewController, asPopoverRelativeToRect: button.bounds, ofView: button, preferredEdge: NSMaxYEdge, behavior: .Semitransient)
		}
	}
	
	
	override var representedObject: AnyObject? {
		didSet {
			/*if let contentController = representedObject as? DocumentContentController {
				PageViewController.setContentController(contentController)
			}*/
		}
	}
}

