//
//  MenuItemsAssistant.swift
//  BurntCocoaUI
//
//  Created by Patrick Smith on 14/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


/**
What each menu item is represented with. Recommended to be used on an enum. This can either be a model enum directly using an extension, or you can use a specific enum.
*/
public protocol MenuItemRepresentative {
	var title: String { get }
	
	typealias UniqueIdentifier: Hashable
	var uniqueIdentifier: UniqueIdentifier { get }
}

public struct MenuItemCustomization<T: MenuItemRepresentative> {
	/**
		Customize the title dynamically, called for each menu item representative.
	*/
	public var title: ((menuItemRepresentative: T) -> String)?
	/**
		Customize the action & target dynamically, called for each menu item representative.
	*/
	public var actionAndTarget: ((menuItemRepresentative: T) -> (action: Selector, target: AnyObject?))?
	/**
		Customize the represented object, called for each menu item representative.
	*/
	public var representedObject: ((menuItemRepresentative: T) -> AnyObject?)?
	/**
		Customize the integer tag, called for each menu item representative.
	*/
	public var tag: ((menuItemRepresentative: T) -> Int?)?
	/**
		Customize the state (NSOnState / NSOffState / NSMixedState), called for each menu item representative.
	*/
	public var state: ((menuItemRepresentative: T) -> Int)?
	/**
		Customize whether the menu item is enabled, called for each menu item representative.
	*/
	public var enabled: ((menuItemRepresentative: T) -> Bool)?
}

public class MenuItemsAssistantCache<T: MenuItemRepresentative> {
	typealias ItemUniqueIdentifier = T.UniqueIdentifier
	
	/// Menu items are cached so they are not thrown away and recreated every time.
	var uniqueIdentifierToMenuItems = [ItemUniqueIdentifier: NSMenuItem]()
}

/**
MenuItemsAssistant
*/
public class MenuItemsAssistant<T: MenuItemRepresentative> {
	public typealias Item = T
	public typealias ItemUniqueIdentifier = Item.UniqueIdentifier
	
	/**
		Pass your implementation of MenuItemRepresentative. Use nil for separator menu items.
	*/
	public var menuItemRepresentatives: [Item?]!
	
	/**
		Customize the menu item’s title, action, etc with this.
	*/
	public var customization = MenuItemCustomization<Item>()
	
	/**
	Creates menu items based on the array of `menuItemRepresentatives`
	
	:param: cache Pass this multiple times to createItems() to reuse menu items.
	*/
	public func createItems(#cache: MenuItemsAssistantCache<Item>?) -> [NSMenuItem] {
		if menuItemRepresentatives == nil {
			fatalError("Must set .menuItemRepresentatives before calling createItems()")
		}
		
		var previousCachedIdentifiers = Set<ItemUniqueIdentifier>()
		if let cache = cache {
			previousCachedIdentifiers.unionInPlace(cache.uniqueIdentifierToMenuItems.keys)
		}
		
		let customization = self.customization
		
		let items = menuItemRepresentatives.map { menuItemRepresentative -> NSMenuItem in
			if let menuItemRepresentative = menuItemRepresentative {
				let title: String = customization.title?(menuItemRepresentative: menuItemRepresentative) ?? menuItemRepresentative.title
				let representedObject: AnyObject? = customization.representedObject?(menuItemRepresentative: menuItemRepresentative)
				let tag: Int = customization.tag?(menuItemRepresentative: menuItemRepresentative) ?? 0
				let state: Int = customization.state?(menuItemRepresentative: menuItemRepresentative) ?? NSOffState
				let enabled: Bool = customization.enabled?(menuItemRepresentative: menuItemRepresentative) ?? true
				
				var action: Selector = nil
				var target: AnyObject?
				if let actionAndTarget = customization.actionAndTarget?(menuItemRepresentative: menuItemRepresentative) {
					action = actionAndTarget.action
					target = actionAndTarget.target
				}
				
				let uniqueIdentifier = menuItemRepresentative.uniqueIdentifier
				previousCachedIdentifiers.remove(uniqueIdentifier)
				
				let item: NSMenuItem
				if let cachedItem = cache?.uniqueIdentifierToMenuItems[uniqueIdentifier] {
					item = cachedItem
				}
				else {
					item = NSMenuItem()
					cache?.uniqueIdentifierToMenuItems[uniqueIdentifier] = item
				}
				
				item.title = title
				item.representedObject = representedObject
				item.action = action
				item.target = target
				item.tag = tag
				item.state = state
				item.enabled = enabled
				
				return item
			}
			else {
				// Separator for nil
				return NSMenuItem.separatorItem()
			}
		}
		
		if let cache = cache {
			for uniqueIdentifier in previousCachedIdentifiers {
				// Clear cache of any items that were not reused.
				cache.uniqueIdentifierToMenuItems.removeValueForKey(uniqueIdentifier)
			}
		}
		
		return items
	}
	
	/**
	Find the item representative for the passed NSMenuItem.
	
	:param: menuItem The menu item to find.
	:param: menuItem The menu items to search within.
	
	:returns: The item representative that matched the menu item.
	*/
	public func itemRepresentativeForMenuItem(menuItemToFind: NSMenuItem, inMenuItems menuItems: [NSMenuItem]) -> T? {
		for (index, menuItem) in enumerate(menuItems) {
			if menuItem === menuItemToFind {
				return menuItemRepresentatives[index]
			}
		}
		
		return nil
	}
}
