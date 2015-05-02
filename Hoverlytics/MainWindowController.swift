//
//  MainWindowController.swift
//  Hoverlytics for Mac
//
//  Created by Patrick Smith on 29/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import HoverlyticsModel


private let sectionUserDefaultKey = "mainSection"


class MainWindowController: NSWindowController, NSToolbarDelegate {
	
	let mainState = MainState()
	typealias MainStateNotification = MainState.Notification
	
	let modelManager = HoverlyticsModel.ModelManager.sharedManager
	
	var mainViewController: ViewController! {
		return contentViewController as! ViewController
	}
	
	var toolbarAssistant: MainWindowToolbarAssistant!
	@IBOutlet var toolbar: NSToolbar! {
		didSet {
			toolbarAssistant = MainWindowToolbarAssistant(toolbar: toolbar, mainState: mainState, modelManager: modelManager)
			
			toolbarAssistant.prepareNewSiteButton = { [unowned self] button in
				button.target = nil
				button.action = "showAddSite:"
			}
			
			toolbarAssistant.prepareSiteSettingsButton = { [unowned self] button in
				button.target = self.mainViewController
				button.action = "showSiteSettings:"
			}
		}
	}
	
	var chosenSiteDidChangeObserver: AnyObject?

    override func windowDidLoad() {
        super.windowDidLoad()
		
		if let window = window {
			window.titleVisibility = .Hidden
			//window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
			//window.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
		}
		
		mainViewController.modelManager = modelManager
		mainViewController.mainState = mainState
		
		let nc = NSNotificationCenter.defaultCenter()
		chosenSiteDidChangeObserver = nc.addObserverForName(MainStateNotification.ChosenSiteDidChange.rawValue, object: self, queue: nil) { [unowned self] note in
			self.window?.title = self.windowTitleForDocumentDisplayName("Main")
		}
    }
	
	deinit {
		let nc = NSNotificationCenter.defaultCenter()
		if let chosenSiteDidChangeObserver: AnyObject = chosenSiteDidChangeObserver {
			nc.removeObserver(chosenSiteDidChangeObserver)
		}
	}
	
	@IBAction func showAddSite(sender: AnyObject?) {
		mainViewController.showAddSiteRelativeToView(toolbarAssistant.addSiteButton)
	}
	
	@IBAction func focusOnSearchPagesField(sender: AnyObject?) {
		toolbarAssistant.focusOnSearchPagesField(sender)
	}
	
	override func windowTitleForDocumentDisplayName(displayName: String) -> String {
		if let site = mainState.chosenSite {
			return site.name
		}
		
		return displayName
	}
}


struct ToolbarItem<ControlClass: NSControl> {
	var control: ControlClass!
	
	typealias PrepareBlock = (control: ControlClass) -> Void
	var prepare: PrepareBlock!
}


class MainWindowToolbarAssistant: NSObject, NSToolbarDelegate {
	let toolbar: NSToolbar
	let mainState: MainState
	let modelManager: HoverlyticsModel.ModelManager
	
	init(toolbar: NSToolbar, mainState: MainState, modelManager: HoverlyticsModel.ModelManager) {
		self.toolbar = toolbar
		self.mainState = mainState
		self.modelManager = modelManager
		
		super.init()
		
		toolbar.delegate = self
		
		startObservingModelManager()
	}
	
	deinit {
		stopObservingModelManager()
	}
	
	var modelManagerNotificationObservers = [ModelManagerNotification: AnyObject]()
	
	func startObservingModelManager() {
		let nc = NSNotificationCenter.defaultCenter()
		let mainQueue = NSOperationQueue.mainQueue()
		
		func addObserver(notificationIdentifier: HoverlyticsModel.ModelManagerNotification, block: (NSNotification!) -> Void) {
			let observer = nc.addObserverForName(notificationIdentifier.notificationName, object: modelManager, queue: mainQueue, usingBlock: block)
			modelManagerNotificationObservers[notificationIdentifier] = observer
		}
		
		addObserver(.AllSitesDidChange) { (notification) in
			self.updateUIForSites()
		}
	}
	
	func stopObservingModelManager() {
		let nc = NSNotificationCenter.defaultCenter()
		
		for (notificationIdentifier, observer) in modelManagerNotificationObservers {
			nc.removeObserver(observer)
		}
		modelManagerNotificationObservers.removeAll(keepCapacity: false)
	}
	
	
	var sitesPopUpButton: NSPopUpButton!
	var chosenSiteChoice: SiteMenuItem = .LoadingSavedSites
	var sitesPopUpButtonAssistant: PopUpButtonAssistant<SiteMenuItem>?
	let siteTag: Int = 1
	
	var siteChoices: [SiteMenuItem?] {
		var result: [SiteMenuItem?] = [
			SiteMenuItem.Choice(.Custom),
			nil
		]
		
		if let allSites = modelManager.allSites {
			let allSites = allSites.sorted({ $0.name < $1.name })
			
			if allSites.count == 0 {
				result.append(
					SiteMenuItem.NoSavedSitesYet
				)
			}
			else {
				for site in allSites {
					result.append(
						SiteMenuItem.Choice(.SavedSite(site))
					)
				}
			}
		}
		else {
			result.append(
				SiteMenuItem.LoadingSavedSites
			)
		}
		
		return result
	}
	
	func updateSitesPopUpButton() {
		#if DEBUG
			//println("updateSitesPopUpButton")
		#endif
		if sitesPopUpButton == nil {
			return
		}
		
		
		var popUpButton = sitesPopUpButton;
		
		popUpButton.target = self
		popUpButton.action = "chosenSiteDidChange:"
		
		
		var popUpButtonAssistant = sitesPopUpButtonAssistant ?? {
			let popUpButtonAssistant = PopUpButtonAssistant<SiteMenuItem>(popUpButton: popUpButton)
			
			let menuAssistant = popUpButtonAssistant.menuAssistant
			menuAssistant.enabledReturner = { siteChoice in
				switch siteChoice {
				case .LoadingSavedSites, .NoSavedSitesYet:
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
		
		
		#if false
		let previouslySelectedItem = sitesPopUpButton.selectedItem
		var previouslySelectedSite = previouslySelectedItem?.representedObject as? Site
		
		func removeNextItemWithTag(tag: Int) -> Bool {
			let index = sitesPopUpButton.indexOfItemWithTag(tag)
			if index == -1 {
				return false
			}
			else {
				sitesPopUpButton.removeItemAtIndex(index)
				return true
			}
		}
		
		while removeNextItemWithTag(siteTag) {}
		
		sitesPopUpButton.target = self
		sitesPopUpButton.action = "chosenSiteDidChange:"
		
		let menu = sitesPopUpButton.menu!
		if let allSites = modelManager.allSites {
			if allSites.count == 0 {
				let menuItem = NSMenuItem(title: "(No Sites)", action: nil, keyEquivalent: "")
				menuItem.tag = siteTag
				menu.insertItem(menuItem, atIndex: 0)
			}
			else {
				let allSites = allSites.sorted({ $0.name < $1.name })
				for site in allSites {
					let menuItem = NSMenuItem(title: site.name, action: nil, keyEquivalent: "")
					menuItem.representedObject = site
					menuItem.tag = siteTag
					menu.addItem(menuItem)
				}
				
				// Select first item by default
				if previouslySelectedSite == nil {
					let defaultSelectedSite = allSites[0]
					mainState.chosenSite = defaultSelectedSite
					previouslySelectedSite = defaultSelectedSite
				}
			}
		}
		else {
			let menuItem = NSMenuItem(title: "(Loading Sites)", action: nil, keyEquivalent: "")
			menuItem.tag = siteTag
			menu.insertItem(menuItem, atIndex: 0)
		}
		
		#if DEBUG
			//println("popup previously selected \(previouslySelectedSite?.name)")
		#endif
		
		if let previouslySelectedSite = previouslySelectedSite {
			let index = sitesPopUpButton.indexOfItemWithRepresentedObject(previouslySelectedSite)
			if index != -1 {
				sitesPopUpButton.selectItemAtIndex(index)
			}
		}
		else {
			updateChosenSiteState()
		}
		#endif
	}
	
	func updateUIForSites() {
		let hasSites = modelManager.allSites?.count > 0
		
		//sitesPopUpButton?.enabled = hasSites
		siteSettingsButton?.enabled = hasSites
		siteSettingsButton?.hidden = !hasSites
		
		updateSitesPopUpButton()
	}
	
	@objc @IBAction func chosenSiteDidChange(sender: NSPopUpButton) {
		updateChosenSiteState()
	}

	func updateChosenSiteState() {
		if let siteMenuItem = sitesPopUpButtonAssistant?.selectedItemRepresentative {
			//mainState.chosenSite = site
			switch siteMenuItem {
			case .Choice(let siteChoice):
				mainState.siteChoice = siteChoice
			default:
				mainState.siteChoice = .Custom
			}
		}
		else {
			mainState.siteChoice = .Custom
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
	
	typealias PrepareButtonCallback = (NSButton) -> Void
	
	var addSiteButton: NSButton!
	var prepareNewSiteButton: PrepareButtonCallback?
	
	var siteSettingsButton: NSButton!
	var prepareSiteSettingsButton: PrepareButtonCallback?
	
	
	var searchPagesField: NSSearchField!
	@IBAction func focusOnSearchPagesField(sender: AnyObject?) {
		if let searchPagesField = searchPagesField {
			searchPagesField.window!.makeFirstResponder(searchPagesField)
		}
	}
	
	
	//var sectionItem = ToolbarItem<NSSegmentedControl>()
	
	
	func toolbarWillAddItem(notification: NSNotification) {
		let userInfo = notification.userInfo!
		let toolbarItem = userInfo["item"] as! NSToolbarItem
		let itemIdentifier = toolbarItem.itemIdentifier
		var sizeToFit = false
		
		if itemIdentifier == "newSiteButton" {
			addSiteButton = toolbarItem.view as! NSButton
			prepareNewSiteButton?(addSiteButton)
		}
		else if itemIdentifier == "chosenSite" {
			sitesPopUpButton = toolbarItem.view as! NSPopUpButton
			updateUIForSites()
		}
		else if itemIdentifier == "siteSettingsButton" {
			siteSettingsButton = toolbarItem.view as! NSButton
			sizeToFit = true
			prepareSiteSettingsButton?(siteSettingsButton)
			updateUIForSites()
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
