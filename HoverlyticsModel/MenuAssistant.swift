//
//  MenuAssistant.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


public protocol MenuItemRepresentative {
	var title: String { get }
	var tag: Int? { get }
	
	typealias UniqueIdentifier: Hashable
	var uniqueIdentifier: UniqueIdentifier { get }
}


public class MenuAssistant<T: MenuItemRepresentative> {
	public let menu: NSMenu?
	
	public init(menu: NSMenu?) {
		self.menu = menu
	}
	
	public var menuItemRepresentatives: [T?]!
	public typealias ItemUniqueIdentifier = T.UniqueIdentifier
	
	public var titleReturner: ((menuItemRepresentative: T) -> String)?
	public var actionAndTargetReturner: ((menuItemRepresentative: T) -> (action: Selector, target: AnyObject?))?
	public var representedObjectReturner: ((menuItemRepresentative: T) -> AnyObject?)?
	public var stateReturner: ((menuItemRepresentative: T) -> Int)?
	
	private var uniqueIdentifierToMenuItems = [ItemUniqueIdentifier: NSMenuItem]()
	
	public func createItems() -> [NSMenuItem] {
		var previousCachedIdentifiers = Set(uniqueIdentifierToMenuItems.keys)
		
		let items = menuItemRepresentatives.map { menuItemRepresentative -> NSMenuItem in
			if let menuItemRepresentative = menuItemRepresentative {
				let title = self.titleReturner?(menuItemRepresentative: menuItemRepresentative) ?? menuItemRepresentative.title
				let tag = menuItemRepresentative.tag ?? 0
				
				var action: Selector = nil
				var target: AnyObject?
				if let actionAndTarget = self.actionAndTargetReturner?(menuItemRepresentative: menuItemRepresentative) {
					action = actionAndTarget.action
					target = actionAndTarget.target
				}
				
				let uniqueIdentifier = menuItemRepresentative.uniqueIdentifier
				previousCachedIdentifiers.remove(uniqueIdentifier)
				
				let item: NSMenuItem
				if let cachedItem = self.uniqueIdentifierToMenuItems[uniqueIdentifier] {
					item = cachedItem
				}
				else {
					item = NSMenuItem()
					self.uniqueIdentifierToMenuItems[uniqueIdentifier] = item
				}
				
				item.tag = tag
				item.title = title
				item.action = action
				item.target = target
				
				if let representedObjectReturner = self.representedObjectReturner {
					item.representedObject = representedObjectReturner(menuItemRepresentative: menuItemRepresentative)
				}
				
				if let stateReturner = self.stateReturner {
					item.state = stateReturner(menuItemRepresentative: menuItemRepresentative)
				}
				else {
					item.state = NSOffState
				}
				
				return item
			}
			else {
				return NSMenuItem.separatorItem()
			}
		}
		
		for uniqueIdentifier in previousCachedIdentifiers {
			// Clear cache of any items that were not reused.
			uniqueIdentifierToMenuItems.removeValueForKey(uniqueIdentifier)
		}
		
		return items
	}
	
	public func updateMenu() {
		if let menu = menu {
			menu.removeAllItems()
			
			let menuItems = createItems()
			for menuItem in menuItems {
				menu.addItem(menuItem)
			}
		}
		else {
			fatalError("Called .updateMenu() when receiver was not initialized with a menu")
		}
	}
	
	public func uniqueIdentifierForMenuItem(menuItem menuItemToFind: NSMenuItem) -> ItemUniqueIdentifier? {
		if let menu = menu {
			let index = menu.indexOfItem(menuItemToFind)
			if let itemRepresentative = menuItemRepresentatives[index] {
				return itemRepresentative.uniqueIdentifier
			}
			
			return nil
		}
		else {
			fatalError("Called .uniqueIdentifierForMenuItem() when receiver was not initialized with a menu")
		}
	}
}


public class PopUpButtonAssistant<T: MenuItemRepresentative> {
	public let popUpButton: NSPopUpButton
	public let menuAssistant: MenuAssistant<T>
	
	public init(popUpButton: NSPopUpButton) {
		self.popUpButton = popUpButton
		menuAssistant = MenuAssistant<T>(menu: popUpButton.menu)
	}
	
	public var menuItemRepresentatives: [T?]! {
		get {
			return menuAssistant.menuItemRepresentatives
		}
		set {
			menuAssistant.menuItemRepresentatives = newValue
		}
	}
	
	public func update() {
		let selectedItem = popUpButton.selectedItem
		
		menuAssistant.updateMenu()
		
		if let selectedItem = selectedItem {
			let selectedItemIndex = popUpButton.indexOfItem(selectedItem)
			if selectedItemIndex != -1 {
				popUpButton.selectItemAtIndex(selectedItemIndex)
			}
		}
	}
}
