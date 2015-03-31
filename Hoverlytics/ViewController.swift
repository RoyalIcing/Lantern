//
//  ViewController.swift
//  Hoverlytics for Mac
//
//  Created by Patrick Smith on 28/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


enum MainSection: Int {
	case Settings = 1
	case ViewPages = 2
}


class ViewController: NSViewController
{
	var currentSection: MainSection?
	
	lazy var editorStoryboard: NSStoryboard = {
		NSStoryboard(name: "Editor", bundle: nil)!
	}()
	lazy var pageViewController: PageViewController = {
		self.editorStoryboard.instantiateControllerWithIdentifier("Page View Controller") as PageViewController
	}()
	
	lazy var siteSettingsStoryboard: NSStoryboard = {
		NSStoryboard(name: "SiteSettings", bundle: nil)!
		}()
	lazy var siteSettingsViewController: SiteSettingsViewController = {
		self.siteSettingsStoryboard.instantiateControllerWithIdentifier("Site Settings View Controller") as SiteSettingsViewController
		}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//println("view did load from storyboard \(self.storyboard) parentViewController: \(self.parentViewController)")
		
		addChildViewController(pageViewController)
		let viewPageView = pageViewController.view
		fillViewWithChildView(viewPageView)
	}
	
	@IBAction func showSiteSettings(button: NSButton) {
		if siteSettingsViewController.presentingViewController != nil {
			dismissViewController(siteSettingsViewController)
		}
		else {
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

