//
//  PlaceholderMenuItemAssistant.swift
//  BurntCocoaUI
//
//  Created by Patrick Smith on 14/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


public class PlaceholderMenuItemAssistant<T: MenuItemRepresentative> {
	public typealias Item = T
	public typealias ItemUniqueIdentifier = Item.UniqueIdentifier
	
	public let placeholderMenuItem: NSMenuItem
	public let itemsAssistant = MenuItemsAssistant<Item>()
	private var menuItems: [NSMenuItem]?
	
	/**
		Pass an array of item representatives for each menu item. Use nil for separators.
	*/
	public var menuItemRepresentatives: [Item?]! {
		get {
			return itemsAssistant.menuItemRepresentatives
		}
		set {
			itemsAssistant.menuItemRepresentatives = newValue
		}
	}
	
	/**
		Customize the menu item’s title, action, etc with this.
	*/
	public var customization: MenuItemCustomization<T> {
		get {
			return itemsAssistant.customization
		}
		set {
			itemsAssistant.customization = newValue
		}
	}
	
	/**
		Menu items are cached here so they are not thrown away and recreated every time.
	*/
	private var itemsCache = MenuItemsAssistantCache<Item>()
	
	public init(placeholderMenuItem: NSMenuItem) {
		self.placeholderMenuItem = placeholderMenuItem
	}
	
	/**
		Populates the menu (that the placeholder item sits within) with menu items created for each member of `menuItemRepresentatives`. The placeholder item is hidden, and items added and removed below.
	*/
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
		
		let newMenuItems = itemsAssistant.createItems(cache: itemsCache)
		var insertIndex = placeholderIndex + 1
		for menuItem in newMenuItems {
			menu.insertItem(menuItem, atIndex: insertIndex)
			insertIndex++
		}
		
		menuItems = newMenuItems
	}
	
	public func itemRepresentativeForMenuItem(menuItemToFind: NSMenuItem) -> Item? {
		if let menuItems = menuItems {
			for (index, menuItem) in enumerate(menuItems) {
				if menuItem === menuItemToFind {
					return menuItemRepresentatives[index]
				}
			}
		}
		
		return nil
	}
}
