//
//  ViewController.swift
//  Hoverlytics for Mac
//
//  Created by Patrick Smith on 28/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation
import LanternModel


class ViewController: NSViewController
{
	var modelManager: LanternModel.ModelManager!
	
	var section: MainSection!
	
	var mainState: MainState! {
		didSet {
			startObservingModelManager()
			updateMainViewForState()
			startObservingBrowserPreferences()
			
			updatePreferredBrowserWidth()
		}
	}
	
	typealias MainStateNotification = MainState.Notification
	
	var mainStateNotificationObservers = [MainStateNotification: AnyObject]()
	var browserPreferencesObserver: NotificationObserver<BrowserPreferences.Notification>!
	
	func startObservingModelManager() {
		let nc = NSNotificationCenter.defaultCenter()
		let mainQueue = NSOperationQueue.mainQueue()
		
		func addObserver(notificationIdentifier: MainState.Notification, block: (NSNotification!) -> Void) {
			let observer = nc.addObserverForName(notificationIdentifier.notificationName, object: mainState, queue: mainQueue, usingBlock: block)
			mainStateNotificationObservers[notificationIdentifier] = observer
		}
		
		addObserver(.ChosenSiteDidChange) { notification in
			self.updateMainViewForState()
		}
	}
	
	func stopObservingModelManager() {
		let nc = NSNotificationCenter.defaultCenter()
		
		for (_, observer) in mainStateNotificationObservers {
			nc.removeObserver(observer)
		}
		mainStateNotificationObservers.removeAll(keepCapacity: false)
	}
	
	func updatePreferredBrowserWidth() {
		pageViewController?.preferredBrowserWidth = mainState.browserPreferences.widthChoice.value
	}
	
	func startObservingBrowserPreferences() {
		browserPreferencesObserver = NotificationObserver<BrowserPreferences.Notification>(object: mainState.browserPreferences)
		
		browserPreferencesObserver.observe(.WidthChoiceDidChange) { notification in
			self.updatePreferredBrowserWidth()
		}
	}
	
	func stopObservingBrowserPreferences() {
		browserPreferencesObserver.stopObserving()
		browserPreferencesObserver = nil
	}
	
	deinit {
		stopObservingModelManager()
		stopObservingBrowserPreferences()
	}
	
	
	lazy var pageStoryboard: NSStoryboard = {
		NSStoryboard(name: "Page", bundle: nil)
	}()
	var mainSplitViewController: NSSplitViewController!
	var pageViewController: PageViewController!
	var statsViewController: StatsViewController!
	
	var lastChosenSite: SiteValues?
	
	func updateMainViewForState() {
		let site = mainState?.chosenSite
		if site?.UUID === lastChosenSite?.UUID {
			return
		}
		lastChosenSite = site
		
		if let site = site {
			let initialURL = site.homePageURL
			mainState.initialHost = initialURL.host
			
			#if false
				pageViewController.GoogleOAuth2TokenJSONString = site.GoogleAPIOAuth2TokenJSONString
				pageViewController.hoverlyticsPanelDidReceiveGoogleOAuth2TokenCallback = { [unowned self] tokenJSONString in
				self.modelManager.setGoogleOAuth2TokenJSONString(tokenJSONString, forSite: site)
				}
			#endif
			
				
			pageViewController.loadURL(initialURL)
			
			
			statsViewController.primaryURL = site.homePageURL
		}
		else {
			statsViewController.primaryURL = nil
			mainState.initialHost = nil
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		mainSplitViewController = NSSplitViewController()
		mainSplitViewController.splitView.vertical = false
		//mainSplitViewController.splitView.dividerStyle = .PaneSplitter
		mainSplitViewController.splitView.dividerStyle = .Thick
		fillWithChildViewController(mainSplitViewController)
		
		let storyboard = self.pageStoryboard
		
		// The top web browser
		let pageViewController = storyboard.instantiateControllerWithIdentifier("Page View Controller") as! PageViewController
		pageViewController.navigatedURLDidChangeCallback = { [unowned self] URL in
			if self.mainState.chosenSite == nil {
				self.mainState.initialHost = URL.host
			}
			
			if pageViewController.crawlWhileBrowsing {
				// Can only crawl the initial 'local' website.
				let isLocal: Bool = {
					if let initialHost = self.mainState.initialHost {
						return URL.host == initialHost
					}
					
					return false
				}()
				
				#if DEBUG
					print("navigatedURLDidChangeCallback \(URL)")
				#endif
				self.statsViewController.didNavigateToURL(URL, crawl: isLocal)
			}
		}
		
		// The bottom page crawler table
		let statsViewController = storyboard.instantiateControllerWithIdentifier("Stats View Controller") as! StatsViewController
		statsViewController.didChooseURLCallback = { URL, pageInfo in
			if pageInfo.baseContentType == .LocalHTMLPage {
				self.pageViewController.loadURL(URL)
			}
		}
		
		
		mainSplitViewController.addSplitViewItem({
			let item = NSSplitViewItem(viewController: pageViewController)
			//item.canCollapse = true
			return item
			}())
		self.pageViewController = pageViewController
		
		mainSplitViewController.addSplitViewItem({
			let item = NSSplitViewItem(viewController: statsViewController)
			//item.canCollapse = true
			return item
		}())
		self.statsViewController = statsViewController
	}
	
	
	//lazy var siteSettingsStoryboard = NSStoryboard(name: "SiteSettings", bundle: nil)
	var siteSettingsStoryboard = NSStoryboard(name: "SiteSettings", bundle: nil)
	lazy var addSiteViewController: SiteSettingsViewController = {
		let vc = self.siteSettingsStoryboard.instantiateControllerWithIdentifier("Add Site View Controller") as! SiteSettingsViewController
		vc.modelManager = self.modelManager
		vc.mainState = self.mainState
		return vc
	}()
	lazy var siteSettingsViewController: SiteSettingsViewController = {
		let vc = self.siteSettingsStoryboard.instantiateControllerWithIdentifier("Site Settings View Controller") as! SiteSettingsViewController
		vc.modelManager = self.modelManager
		vc.mainState = self.mainState
		return vc
	}()
	
	
	@IBAction func showAddSiteRelativeToView(relativeView: NSView) {
		if addSiteViewController.presentingViewController != nil {
			dismissViewController(addSiteViewController)
		}
		else {
			presentViewController(addSiteViewController, asPopoverRelativeToRect: relativeView.bounds, ofView: relativeView, preferredEdge: NSRectEdge.MaxY, behavior: .Semitransient)
		}
	}
	
	
	@IBAction func showSiteSettings(button: NSButton) {
		if siteSettingsViewController.presentingViewController != nil {
			dismissViewController(siteSettingsViewController)
		}
		else {
			if let chosenSite = mainState?.chosenSite {
				siteSettingsViewController.site = chosenSite
				siteSettingsViewController.updateUIWithSiteValues(chosenSite)
				
				let modelManager = self.modelManager
				siteSettingsViewController.willClose = { siteSettingsViewController in
					let UUID = chosenSite.UUID
					do {
						let siteValues = try siteSettingsViewController.copySiteValuesFromUI(UUID: UUID)
						modelManager.updateSiteWithUUID(UUID, withValues: siteValues)
					}
					catch {
						NSApplication.sharedApplication().presentError(error as NSError, modalForWindow: self.view.window!, delegate: nil, didPresentSelector: nil, contextInfo: nil)
					}
				}
				
				presentViewController(siteSettingsViewController, asPopoverRelativeToRect: button.bounds, ofView: button, preferredEdge: NSRectEdge.MaxY, behavior: .Semitransient)
			}
		}
	}
	
	override func supplementalTargetForAction(action: Selector, sender: AnyObject?) -> AnyObject? {
		if statsViewController.respondsToSelector(action) {
			return statsViewController
		}
		
		if pageViewController.respondsToSelector(action) {
			return pageViewController
		}
		
		return super.supplementalTargetForAction(action, sender: sender)
	}
	
	
	override var representedObject: AnyObject? {
		didSet {
			
		}
	}
}

