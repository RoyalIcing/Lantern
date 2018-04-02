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


class ViewController : NSViewController
{
	var modelManager: LanternModel.ModelManager!
	
	// MARK: Page Mapper
	
	var pageMapper: PageMapper?
	
	func clearPageMapper() {
		pageMapper?.cancel()
		pageMapper = nil
	}
	
	var pageMapperCreatedCallbacks: [UUID: (PageMapper) -> ()] = [:]
	func createPageMapper(primaryURL: URL) -> PageMapper? {
		clearPageMapper()
		pageMapper = PageMapper(primaryURL: primaryURL)
		
		if let pageMapper = pageMapper {
			for (_, callback) in pageMapperCreatedCallbacks {
				callback(pageMapper)
			}
		}
		
		return pageMapper
	}
	
	subscript(pageMapperCreatedCallback uuid: UUID) -> ((PageMapper) -> ())? {
		get {
			return pageMapperCreatedCallbacks[uuid]
		}
		set(callback) {
			pageMapperCreatedCallbacks[uuid] = callback
		}
	}
	
	var activeURL: URL? {
		didSet {
			activeURLChanged()
		}
	}
	
	var activeURLChangedCallbacks: [UUID: (URL?) -> ()] = [:]
	func activeURLChanged() {
		for (_, callback) in activeURLChangedCallbacks {
			callback(activeURL)
		}
		
		guard let url = activeURL else { return }
		
		if self.mainState.chosenSite == nil {
			self.mainState.initialHost = url.host
		}
		
		self.view.window?.title = url.host ?? url.absoluteString
		
		if pageViewController.crawlWhileBrowsing {
			// Can only crawl the initial 'local' website.
			let isLocal: Bool = {
				if let initialHost = self.mainState.initialHost {
					return url.host == initialHost
				}
				
				return false
			}()
			
			#if DEBUG
				print("navigatedURLDidChangeCallback \(url)")
			#endif
			self.statsViewController.didNavigateToURL(url, crawl: isLocal)
		}
	}
	
	subscript(activeURLChangedCallback uuid: UUID) -> ((URL?) -> ())? {
		get {
			return activeURLChangedCallbacks[uuid]
		}
		set(callback) {
			activeURLChangedCallbacks[uuid] = callback
		}
	}
	
	// MARK: -
	
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
		
		func addObserver(_ notificationIdentifier: MainState.Notification, block: @escaping (Notification?) -> ()) {
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
		
		browserPreferencesObserver.observe(.widthChoiceDidChange) { notification in
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
		mainSplitViewController.splitView.dividerStyle = .thin
		
		let storyboard = self.pageStoryboard
		
		// The top web browser
		let pageViewController = storyboard.instantiateController(withIdentifier: "Page View Controller") as! PageViewController
		
		// The bottom page crawler table
		let statsViewController = storyboard.instantiateController(withIdentifier: "Stats View Controller") as! StatsViewController
		statsViewController.didChooseURLCallback = { url, pageInfo in
			if pageInfo.baseContentType == .localHTMLPage {
				// FIXME: use active URL instead?
				self.pageViewController.loadURL(url)
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
		
		fill(withChildViewController: mainSplitViewController)
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
			//var chosenSite = mainState?.chosenSite
			//var chosenSite = chosenSite
			
			//let activeURL = self.activeURL
			
//			if let activeURL = activeURL {
//				chosenSite = chosenSite.map{ inner in
//					var inner = inner
//					inner.homePageURL = activeURL
//					return inner
//				} ?? SiteValues(name: "", homePageURL: activeURL)
//			}
			
			let modelManager = self.modelManager!
			
			if let activeURL = activeURL {
				let chosenSite = modelManager.siteWithURL(url: activeURL)
				print("EDIT CHOSEN SITE", "\(String(describing: chosenSite))")
				siteSettingsViewController.state = (url: activeURL, favoriteName: chosenSite?.name)
			}
			else {
				siteSettingsViewController.state = nil
			}
			// TODO
			
			siteSettingsViewController.saveSite = { siteSettingsViewController in
				do {
					if let (siteValues, saveInFavorites) = try siteSettingsViewController.copySiteValuesFromUI() {
						if saveInFavorites {
							modelManager.addOrUpdateSite(values: siteValues)
						}
						else {
							modelManager.removeSite(url: siteValues.homePageURL)
						}
						
						self.pageViewController.loadURL(siteValues.homePageURL)
					}
				}
				catch {
					NSApplication.shared().presentError(error as NSError, modalFor: self.view.window!, delegate: nil, didPresent: nil, contextInfo: nil)
				}
			}
			
			presentViewController(siteSettingsViewController, asPopoverRelativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.maxY, behavior: .semitransient)
		}
	}
	
	@IBAction func toggleShownViews(_ sender: Any?) {
			pageViewController.toggleShownViews(sender)
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

extension ViewController : PageMapperProvider {}
