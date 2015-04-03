//
//  ViewController.swift
//  Hoverlytics for Mac
//
//  Created by Patrick Smith on 28/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import HoverlyticsModel


class ViewController: NSViewController
{
	var modelManager: HoverlyticsModel.ModelManager!
	
	var mainState: HoverlyticsModel.MainState! {
		didSet {
			startObservingModelManager()
			updateMainViewForState()
		}
	}
	
	var mainStateNotificationObservers = [MainStateNotification: AnyObject]()
	
	func startObservingModelManager() {
		let nc = NSNotificationCenter.defaultCenter()
		let mainQueue = NSOperationQueue.mainQueue()
		
		func addObserver(notificationIdentifier: MainStateNotification, block: (NSNotification!) -> Void) {
			let observer = nc.addObserverForName(notificationIdentifier.notificationName, object: mainState, queue: mainQueue, usingBlock: block)
			mainStateNotificationObservers[notificationIdentifier] = observer
		}
		
		addObserver(.ChosenSiteDidChange) { (notification) in
			self.updateMainViewForState()
		}
	}
	
	func stopObservingModelManager() {
		let nc = NSNotificationCenter.defaultCenter()
		
		for (notificationIdentifier, observer) in mainStateNotificationObservers {
			nc.removeObserver(observer)
		}
		mainStateNotificationObservers.removeAll(keepCapacity: false)
	}
	
	lazy var pageStoryboard: NSStoryboard = {
		NSStoryboard(name: "Page", bundle: nil)!
	}()
	var pageViewController: PageViewController!
	
	func removePageViewController() {
		if pageViewController?.parentViewController != nil {
			pageViewController.removeFromParentViewController()
			let pageView = pageViewController.view
			pageView.removeFromSuperview()
			pageViewController = nil
		}
	}
	
	func createPageViewControllerForSite(site: Site) {
		// Create page view controller.
		let pageViewController = self.pageStoryboard.instantiateControllerWithIdentifier("Page View Controller") as PageViewController
		
		pageViewController.GoogleOAuth2TokenJSONString = site.GoogleAPIOAuth2TokenJSONString
		pageViewController.hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback = { [unowned self] tokenJSONString in
			self.modelManager.setGoogleOAuth2TokenJSONString(tokenJSONString, forSite: site)
		}
		
		addChildViewController(pageViewController)
		let pageView = pageViewController.view
		fillViewWithChildView(pageView)
		
		pageViewController.loadURL(site.homePageURL)
		
		self.pageViewController = pageViewController
	}
	
	var lastChosenSite: Site!
	
	func updateMainViewForState() {
		if let chosenSite = mainState?.chosenSite {
			println("updateMainViewForState \(chosenSite.name) before \(lastChosenSite?.name)")
			// Make sure page view controller is not loaded more than once for a site.
			if chosenSite.identifier == lastChosenSite?.identifier {
				return
			}
			lastChosenSite = chosenSite
			
			removePageViewController()
			createPageViewControllerForSite(chosenSite)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//println("view did load from storyboard \(self.storyboard) parentViewController: \(self.parentViewController)")
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
				
				let modelManager = self.modelManager
				siteSettingsViewController.willClose = { siteSettingsViewController in
					let (siteValues, error) = siteSettingsViewController.copySiteValuesFromUI()
					if let siteValues = siteValues {
						modelManager.updateSiteWithValues(chosenSite, siteValues: siteValues)
					}
				}
				
				presentViewController(siteSettingsViewController, asPopoverRelativeToRect: button.bounds, ofView: button, preferredEdge: NSMaxYEdge, behavior: .Semitransient)
			}
		}
	}
	
	
	override var representedObject: AnyObject? {
		didSet {
			
		}
	}
}

