//
//	ViewController.swift
//	Hoverlytics for Mac
//
//	Created by Patrick Smith on 28/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
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
		let nc = NotificationCenter.default
		let mainQueue = OperationQueue.main
		
		func addObserver(_ notificationIdentifier: MainState.Notification, block: @escaping (Notification!) -> Void) {
			let observer = nc.addObserver(forName: NSNotification.Name(rawValue: notificationIdentifier.notificationName), object: mainState, queue: mainQueue, using: block)
			mainStateNotificationObservers[notificationIdentifier] = observer
		}
		
		addObserver(.ChosenSiteDidChange) { notification in
			self.updateMainViewForState()
		}
	}
	
	func stopObservingModelManager() {
		let nc = NotificationCenter.default
		
		for (_, observer) in mainStateNotificationObservers {
			nc.removeObserver(observer)
		}
		mainStateNotificationObservers.removeAll(keepingCapacity: false)
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
		if site?.UUID == lastChosenSite?.UUID {
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
		mainSplitViewController.splitView.isVertical = false
		//mainSplitViewController.splitView.dividerStyle = .PaneSplitter
		mainSplitViewController.splitView.dividerStyle = .thick
		fill(withChildViewController: mainSplitViewController)
		
		let storyboard = self.pageStoryboard
		
		// The top web browser
		let pageViewController = storyboard.instantiateController(withIdentifier: "Page View Controller") as! PageViewController
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
		let statsViewController = storyboard.instantiateController(withIdentifier: "Stats View Controller") as! StatsViewController
		statsViewController.didChooseURLCallback = { URL, pageInfo in
			if pageInfo.baseContentType == .localHTMLPage {
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
		let vc = self.siteSettingsStoryboard.instantiateController(withIdentifier: "Add Site View Controller") as! SiteSettingsViewController
		vc.modelManager = self.modelManager
		vc.mainState = self.mainState
		return vc
	}()
	lazy var siteSettingsViewController: SiteSettingsViewController = {
		let vc = self.siteSettingsStoryboard.instantiateController(withIdentifier: "Site Settings View Controller") as! SiteSettingsViewController
		vc.modelManager = self.modelManager
		vc.mainState = self.mainState
		return vc
	}()
	
	
	@IBAction func showAddSiteRelativeToView(_ relativeView: NSView) {
		if addSiteViewController.presenting != nil {
			dismissViewController(addSiteViewController)
		}
		else {
			presentViewController(addSiteViewController, asPopoverRelativeTo: relativeView.bounds, of: relativeView, preferredEdge: NSRectEdge.maxY, behavior: .semitransient)
		}
	}
	
	
	@IBAction func showSiteSettings(_ button: NSButton) {
		if siteSettingsViewController.presenting != nil {
			dismissViewController(siteSettingsViewController)
		}
		else {
			if let chosenSite = mainState?.chosenSite {
				siteSettingsViewController.site = chosenSite
				siteSettingsViewController.updateUIWithSiteValues(chosenSite)
				
				let modelManager = self.modelManager!
				siteSettingsViewController.willClose = { siteSettingsViewController in
					let UUID = chosenSite.UUID
					do {
						let siteValues = try siteSettingsViewController.copySiteValuesFromUI(UUID: UUID)
						modelManager.updateSiteWithUUID(UUID, withValues: siteValues)
					}
					catch {
						NSApplication.shared().presentError(error as NSError, modalFor: self.view.window!, delegate: nil, didPresent: nil, contextInfo: nil)
					}
				}
				
				presentViewController(siteSettingsViewController, asPopoverRelativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.maxY, behavior: .semitransient)
			}
		}
	}
	
	override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
		if statsViewController.responds(to: action) {
			return statsViewController
		}
		
		if pageViewController.responds(to: action) {
			return pageViewController
		}
		
		return super.supplementalTarget(forAction: action, sender: sender)
	}
	
	
	override var representedObject: Any? {
		didSet {
			
		}
	}
}

