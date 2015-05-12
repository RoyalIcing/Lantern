//
//  MenuAssistant.swift
//  BurntCocoaUI
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


/**
What each menu item is represented with. Recommended to be used on an enum. This can either be a model enum directly using an extension, or you can use a specific enum.
*/
public protocol MenuItemRepresentative {
	var title: String { get }
	var tag: Int? { get }
	
	typealias UniqueIdentifier: Hashable
	var uniqueIdentifier: UniqueIdentifier { get }
}

/**
MenuAssistant
*/
public class MenuAssistant<T: MenuItemRepresentative> {
	public let menu: NSMenu?
	
	/**
	Create a new menu assistant.
	
	You can pass a NSMenu you would like to automatically update. Alternatively, initialize with nil and you can call createItems() yourself, if you were combining the items from several menu assistants for example.
	
	:param: menu Pass a NSMenu you would like to automatically update.
	*/
	public init(menu: NSMenu?) {
		self.menu = menu
	}
	
	/// Pass your implementation of MenuItemRepresentative. Use nil for separators.
	public var menuItemRepresentatives: [T?]!
	public typealias Item = T
	public typealias ItemUniqueIdentifier = T.UniqueIdentifier
	
	/// Customize the title dynamically, called for each menu item representative.
	public var titleReturner: ((menuItemRepresentative: T) -> String)?
	/// Customize the action & target dynamically, called for each menu item representative.
	public var actionAndTargetReturner: ((menuItemRepresentative: T) -> (action: Selector, target: AnyObject?))?
	/// Customize the represented object, called for each menu item representative.
	public var representedObjectReturner: ((menuItemRepresentative: T) -> AnyObject?)?
	/// Customize the state (NSOnState / NSOffState / NSMixedState), called for each menu item representative.
	public var stateReturner: ((menuItemRepresentative: T) -> Int)?
	/// Customize whether the menu item is enabled, called for each menu item representative.
	public var enabledReturner: ((menuItemRepresentative: T) -> Bool)?
	
	/// Menu items are cached so they are not thrown away and recreated every time.
	private var uniqueIdentifierToMenuItems = [ItemUniqueIdentifier: NSMenuItem]()
	
	/**
	Creates menu items based on the array of representatives
	*/
	public func createItems() -> [NSMenuItem] {
		if menuItemRepresentatives == nil {
			fatalError("Must set .menuItemRepresentatives before calling createItems()")
		}
		
		var previousCachedIdentifiers = Set(uniqueIdentifierToMenuItems.keys)
		
		let items = menuItemRepresentatives.map { menuItemRepresentative -> NSMenuItem in
			if let menuItemRepresentative = menuItemRepresentative {
				let title: String = self.titleReturner?(menuItemRepresentative: menuItemRepresentative) ?? menuItemRepresentative.title
				let tag: Int = menuItemRepresentative.tag ?? 0
				let state: Int = self.stateReturner?(menuItemRepresentative: menuItemRepresentative) ?? NSOffState
				let enabled: Bool = self.enabledReturner?(menuItemRepresentative: menuItemRepresentative) ?? true
				let representedObject: AnyObject? = self.representedObjectReturner?(menuItemRepresentative: menuItemRepresentative)
				
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
				
				item.title = title
				item.tag = tag
				item.state = state
				item.action = action
				item.target = target
				item.enabled = enabled
				item.representedObject = representedObject
				
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
	
	/**
	Updates the menu. fatalError() if the receiver was not initialized with a menu.
	*/
	public func updateMenu() -> NSMenu {
		if let menu = menu {
			menu.removeAllItems()
			
			let menuItems = createItems()
			for menuItem in menuItems {
				menu.addItem(menuItem)
			}
			
			return menu
		}
		else {
			fatalError("Called .updateMenu() when receiver was not initialized with a menu")
		}
	}
	
	/**
	Find the .uniqueIdentifier for the passed NSMenuItem. fatalError() if the receiver was initialized with a menu.
	
	:param: menuItem The menu item inside the receiver’s menu.
	
	:returns: The unique identifier for the representative that matched the menu item.
	*/
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


public class PlaceholderMenuItemAssistant<T: MenuItemRepresentative> {
	public let menuAssistant: MenuAssistant<T>
	private let placeholderMenuItem: NSMenuItem
	private var menuItems: [NSMenuItem]?
	
	private init(menuAssistant: MenuAssistant<T>, placeholderMenuItem: NSMenuItem) {
		self.menuAssistant = menuAssistant
		self.placeholderMenuItem = placeholderMenuItem
	}
	
	public func update() {
		assert(placeholderMenuItem.menu != nil, "`placeholderMenuItem` must be in a menu.")
		
		placeholderMenuItem.hidden = true
		let menu = placeholderMenuItem.menu!
		
		if let oldMenuItems = menuItems {
			for oldMenuItem in oldMenuItems {
				oldMenuItem.menu?.removeItem(oldMenuItem)
			}
		}
		
		let placeholderIndex = menu.indexOfItem(placeholderMenuItem)
		
		let newMenuItems = menuAssistant.createItems()
		var insertIndex = placeholderIndex + 1
		for menuItem in newMenuItems {
			menu.insertItem(menuItem, atIndex: insertIndex)
			insertIndex++
		}
		
		menuItems = newMenuItems
	}
	
	public func itemRepresentativeForMenuItem(menuItemToFind: NSMenuItem) -> T? {
		if let menuItems = menuItems {
			for (index, menuItem) in enumerate(menuItems) {
				if menuItem === menuItemToFind {
					return menuAssistant.menuItemRepresentatives[index]
				}
			}
		}
			
		return nil
	}
}

extension MenuAssistant {
	public func assistPlaceholderMenuItem(placeholderMenuItem: NSMenuItem) -> PlaceholderMenuItemAssistant<T> {
		return PlaceholderMenuItemAssistant<T>(menuAssistant: self, placeholderMenuItem: placeholderMenuItem)
	}
}
