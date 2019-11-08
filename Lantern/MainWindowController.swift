//
//	MainWindowController.swift
//	Hoverlytics for Mac
//
//	Created by Patrick Smith on 29/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation
import BurntCocoaUI
import LanternModel
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
	switch (lhs, rhs) {
	case let (l?, r?):
		return l < r
	case (nil, _?):
		return true
	default:
		return false
	}
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
	switch (lhs, rhs) {
	case let (l?, r?):
		return l > r
	default:
		return rhs < lhs
	}
}



private let sectionUserDefaultKey = "mainSection"


class MainWindowController: NSWindowController {
	
	let mainState = MainState()
	
	let modelManager = LanternModel.ModelManager.sharedManager
	
	var mainViewController: ViewController! {
		return contentViewController as! ViewController
	}
	
	let crawlerProviderListenerUUID = UUID()
	
	var toolbarAssistant: MainWindowToolbarAssistant!
	@IBOutlet var toolbar: NSToolbar! {
		didSet {
			toolbarAssistant = MainWindowToolbarAssistant(toolbar: toolbar, mainState: mainState, modelManager: modelManager)
			
			toolbarAssistant.prepareURLSettingsButton = { [unowned self] button in
				button.target = self.mainViewController
				button.action = #selector(ViewController.showURLSettings(_:))
			}
			
			toolbarAssistant.prepareToggleViewControl = { [unowned self] segmentedControl in
				segmentedControl.target = self.mainViewController
				segmentedControl.action = #selector(ViewController.toggleShownViews(_:))
			}
		}
	}
	
	var chosenSiteDidChangeObserver: AnyObject?

	override func windowDidLoad() {
		super.windowDidLoad()
		
		if let window = window {
			window.delegate = self
			
			// Prefer tabbing
			window.tabbingIdentifier = "main"
			window.tabbingMode = .preferred
			
			// Combine title and toolbar
			window.titleVisibility = .hidden
			
			//window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
			//window.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
			
			window.title = "New"
		}
		
		mainViewController.modelManager = modelManager
		mainViewController.mainState = mainState
		
		mainViewController.changeCallback = { [weak self] change in
			guard let self = self else { return }
			switch change {
			case let .toggleableViews(shown):
				self.toolbarAssistant.updateToggleViewControl(shownViews: shown)
			}
		}
		
		let nc = NotificationCenter.default
		chosenSiteDidChangeObserver = nc.addObserver(forName: MainState.chosenSiteDidChangeNotification, object: mainState, queue: nil) { [weak self] note in
			guard let self = self else { return }
			self.window?.title = self.windowTitle(forDocumentDisplayName: "New")
		}
		
		if let provider = mainViewController.pageMapperProvider {
			provider[activeURLChangedCallback: crawlerProviderListenerUUID] = { [weak self] url in
				guard let self = self else { return }
				if let url = url, let button = self.toolbarAssistant.urlSettingsButton {
					button.title = url.absoluteString
					self.toolbarAssistant.updateChosenSiteState()
				}
			}
		}
	}
	
	deinit {
		let nc = NotificationCenter.default
		if let chosenSiteDidChangeObserver: AnyObject = chosenSiteDidChangeObserver {
			nc.removeObserver(chosenSiteDidChangeObserver)
		}
	}
	
	@IBAction func openURL(_ sender: Any?) {
		print("OPEN URL")
		guard let button = toolbarAssistant.urlSettingsButton else { return }
		mainViewController.showURLSettings(button)
	}
	
	@IBAction func focusOnSearchPagesField(_ sender: Any?) {
		toolbarAssistant.focusOnSearchPagesField(sender)
	}
	
	override func windowTitle(forDocumentDisplayName displayName: String) -> String {
		return mainState.chosenSite?.name ?? displayName
	}
}

extension MainWindowController: NSWindowDelegate {
	
}


struct ToolbarItem<ControlClass: NSControl> {
	var control: ControlClass!
	
	typealias PrepareBlock = (_ control: ControlClass) -> ()
	var prepare: PrepareBlock!
}


class MainWindowToolbarAssistant: NSObject, NSToolbarDelegate {
	let toolbar: NSToolbar
	let mainState: MainState
	let modelManager: LanternModel.ModelManager
	
	init(toolbar: NSToolbar, mainState: MainState, modelManager: LanternModel.ModelManager) {
		self.toolbar = toolbar
		self.mainState = mainState
		self.modelManager = modelManager
		
		super.init()
		
		let nc = NotificationCenter.default
		nc.addObserver(self, selector: #selector(mainState_chosenSiteDidChange(_:)), name: MainState.chosenSiteDidChangeNotification, object: mainState)
		
		toolbar.delegate = self
		
		startObservingModelManager()
		startObservingBrowserPreferences()
	}
	
	deinit {
		stopObservingModelManager()
		stopObservingBrowserPreferences()
	}
	
	@objc func mainState_chosenSiteDidChange(_ notification: NSNotification) {
		if let chosenSite = mainState.chosenSite {
			let choice = SiteMenuItem.choice(.savedSite(chosenSite))
			sitesPopUpButtonAssistant?.selectedUniqueIdentifier = choice.uniqueIdentifier
		}
	}
	
	var modelManagerNotificationObservers = [ModelManagerNotification: AnyObject]()
	
	func startObservingModelManager() {
		let nc = NotificationCenter.default
		let mainQueue = OperationQueue.main
		
		func addObserver(_ notificationIdentifier: LanternModel.ModelManagerNotification, block: @escaping (Notification?) -> ()) {
			let observer = nc.addObserver(forName: Notification.Name(notificationIdentifier.notificationName), object: modelManager, queue: mainQueue, using: block)
			modelManagerNotificationObservers[notificationIdentifier] = observer
		}
		
		addObserver(.allSitesDidChange) { (notification) in
			self.updateUIForSites()
		}
	}
	
	func stopObservingModelManager() {
		let nc = NotificationCenter.default
		
		for (_, observer) in modelManagerNotificationObservers {
			nc.removeObserver(observer)
		}
		modelManagerNotificationObservers.removeAll()
	}
	
	
	var sitesPopUpButton: NSPopUpButton!
	var chosenSiteChoice: SiteMenuItem = .loadingSavedSites
	var sitesPopUpButtonAssistant: PopUpButtonAssistant<SiteMenuItem>?
	let siteTag: Int = 1
	
	var siteChoices: [SiteMenuItem?] {
		var result: [SiteMenuItem?] = [
			SiteMenuItem.choice(.custom),
			nil
		]
		
		if let allSites = modelManager.allSites {
			let allSites = allSites.sorted(by: { $0.name < $1.name })
			
			if allSites.count == 0 {
				result.append(
					SiteMenuItem.noSavedSitesYet
				)
			}
			else {
				for site in allSites {
					result.append(
						SiteMenuItem.choice(.savedSite(site))
					)
				}
			}
		}
		else {
			result.append(
				SiteMenuItem.loadingSavedSites
			)
		}
		
		return result
	}
	
	func updateSitesPopUpButton() {
		guard let popUpButton = sitesPopUpButton
			else { return }
		
		popUpButton.target = self
		popUpButton.action = #selector(MainWindowToolbarAssistant.chosenSiteDidChange(_:))
		
		
		let popUpButtonAssistant = sitesPopUpButtonAssistant ?? {
			let popUpButtonAssistant = PopUpButtonAssistant<SiteMenuItem>(popUpButton: popUpButton)
			
			let menuAssistant = popUpButtonAssistant.menuAssistant
			menuAssistant.customization.enabled = { siteChoice in
				switch siteChoice {
				case .loadingSavedSites, .noSavedSitesYet:
					return false
				default:
					return true
				}
			}
			
			self.sitesPopUpButtonAssistant = popUpButtonAssistant
			
			return popUpButtonAssistant
		}()
		
		popUpButtonAssistant.menuItemRepresentatives = siteChoices
		popUpButtonAssistant.update()
	}
	
	func updateUIForSites() {
		let hasSites = modelManager.allSites?.count > 0
		
		//sitesPopUpButton?.enabled = hasSites
		urlSettingsButton?.isEnabled = hasSites
		urlSettingsButton?.isHidden = !hasSites
		
		updateSitesPopUpButton()
	}
	
	@objc @IBAction func chosenSiteDidChange(_ sender: NSPopUpButton) {
		updateChosenSiteState()
	}

	func updateChosenSiteState() {
		if let siteMenuItem = sitesPopUpButtonAssistant?.selectedItemRepresentative {
			//mainState.chosenSite = site
			switch siteMenuItem {
			case .choice(let siteChoice):
				mainState.siteChoice = siteChoice
			default:
				mainState.siteChoice = .custom
			}
		}
		else {
			mainState.siteChoice = .custom
		}
		
		/*if let selectedItem = sitesPopUpButton.selectedItem {
			if let site = selectedItem.representedObject as? Site {
				println("chosenSite TO \(site.name)")
				mainState.chosenSite = site
			}
			else {
				println("chosenSite TO nil")
				mainState.chosenSite = nil
			}
		}*/
	}
	
	var addSiteButton: NSButton?
	var prepareNewSiteButton: ((NSButton) -> ())?
	
	var urlSettingsButton: NSButton!
	var prepareURLSettingsButton: ((NSButton) -> ())?
	
	var toggleViewControl: NSSegmentedControl!
	var prepareToggleViewControl: ((NSSegmentedControl) -> ())?
	func updateToggleViewControl(shownViews: Set<ToggleableViewIdentifier>) {
		toggleViewControl.setSelected(shownViews.contains(.browser), forSegment: 0)
		toggleViewControl.setSelected(shownViews.contains(.meta), forSegment: 1)
	}
	
	var viewportWidthAssistant: PopUpButtonAssistant<BrowserWidthChoice>?
	@IBAction func changeViewportWidth(_ sender: Any?) {
		guard let widthChoice = viewportWidthAssistant?.selectedItemRepresentative else { return }
		BrowserPreferences.shared.widthChoice = widthChoice
	}
	
	var browserPreferencesObserver: NotificationObserver<BrowserPreferences.Notification>!
	func startObservingBrowserPreferences() {
		let preferences = BrowserPreferences.shared
		browserPreferencesObserver = NotificationObserver<BrowserPreferences.Notification>(object: preferences)
		
		browserPreferencesObserver.observe(.widthChoiceDidChange) { notification in
			self.viewportWidthAssistant?.selectedUniqueIdentifier = preferences.widthChoice.uniqueIdentifier
		}
	}
	
	func stopObservingBrowserPreferences() {
		browserPreferencesObserver.stopObserving()
		browserPreferencesObserver = nil
	}
	
	var searchPagesField: NSSearchField!
	@IBAction func focusOnSearchPagesField(_ sender: Any?) {
		if let searchPagesField = searchPagesField {
			searchPagesField.window!.makeFirstResponder(searchPagesField)
		}
	}
	
	
	//var sectionItem = ToolbarItem<NSSegmentedControl>()
	
	
	func toolbarWillAddItem(_ notification: Notification) {
		let userInfo = notification.userInfo!
		let toolbarItem = userInfo["item"] as! NSToolbarItem
		let itemIdentifier = toolbarItem.itemIdentifier.rawValue
		var sizeToFit = false
		
		if itemIdentifier == "newSiteButton" {
			let addSiteButton = toolbarItem.view as! NSButton
			self.addSiteButton = addSiteButton
			prepareNewSiteButton?(addSiteButton)
		}
		else if itemIdentifier == "chosenSite" {
			sitesPopUpButton = toolbarItem.view as! NSPopUpButton
			updateUIForSites()
		}
		else if itemIdentifier == "siteSettingsButton" {
			urlSettingsButton = toolbarItem.view as! NSButton
			//sizeToFit = true
			prepareURLSettingsButton?(urlSettingsButton)
			updateUIForSites()
		}
		else if itemIdentifier == "viewportWidth" {
			let popUpButton = toolbarItem.view as! NSPopUpButton
			popUpButton.target = self
			popUpButton.action = #selector(changeViewportWidth(_:))
			
			let preferences = BrowserPreferences.shared
			let assistant = PopUpButtonAssistant<BrowserWidthChoice>(popUpButton: popUpButton)
			assistant.menuItemRepresentatives = BrowserWidthChoice.allChoices
			print("WIDTH \(preferences.widthChoice)")
			assistant.update()
			assistant.selectedUniqueIdentifier = preferences.widthChoice
			self.viewportWidthAssistant = assistant
		}
		else if itemIdentifier == "showToggles" {
			toggleViewControl = toolbarItem.view as! NSSegmentedControl
			prepareToggleViewControl?(toggleViewControl)
		}
		else if itemIdentifier == "searchPages" {
			searchPagesField = toolbarItem.view as! NSSearchField
		}
		
		if sizeToFit {
			let fittingSize = toolbarItem.view!.fittingSize
			toolbarItem.minSize = fittingSize
			toolbarItem.maxSize = fittingSize
		}
	}
}
