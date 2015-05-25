//
//  MenuAssistant.swift
//  BurntCocoaUI
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


/**
MenuAssistant
*/
public class MenuAssistant<T: MenuItemRepresentative> {
	public typealias Item = T
	public typealias ItemUniqueIdentifier = Item.UniqueIdentifier
	
	public let menu: NSMenu
	
	/**
	Create a new menu assistant.
	
	:param: menu Pass the NSMenu you would like to automatically populate.
	*/
	public init(menu: NSMenu) {
		self.menu = menu
	}
	
	public let itemsAssistant = MenuItemsAssistant<Item>()
	
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
	Menu items are cached so they are not thrown away and recreated every time.
	*/
	private var itemsCache = MenuItemsAssistantCache<Item>()
	
	/**
	Populates the menu with menu items created for each member of `menuItemRepresentatives`
	*/
	public func update() -> NSMenu {
		menu.removeAllItems()
		
		let menuItems = itemsAssistant.createItems(cache: itemsCache)
		for menuItem in menuItems {
			menu.addItem(menuItem)
		}
		
		return menu
	}
	
	/**
	Find the item representative for the passed NSMenuItem index.
	
	:param: menuItemIndex The index of the menu item to find inside the receiver’s menu.
	
	:returns: The item representative that matched the menu item index.
	*/
	public func itemRepresentativeForMenuItemAtIndex(menuItemIndex: Int) -> Item? {
		return menuItemRepresentatives[menuItemIndex]
	}
	
	/**
	Find the unique identifier for the passed NSMenuItem index.
	
	:param: menuItemIndex The index of the menu item to find inside the receiver’s menu.
	
	:returns: The unique identifier that matched the menu item index.
	*/
	public func uniqueIdentifierForMenuItemAtIndex(menuItemIndex: Int) -> ItemUniqueIdentifier? {
		return itemRepresentativeForMenuItemAtIndex(menuItemIndex)?.uniqueIdentifier
	}
	
	/**
	Find the item representative for the passed NSMenuItem.
	
	:param: menuItem The menu item to find inside the receiver’s menu.
	
	:returns: The item representative that matched the menu item.
	*/
	public func itemRepresentativeForMenuItem(menuItem menuItemToFind: NSMenuItem) -> Item? {
		let index = menu.indexOfItem(menuItemToFind)
		if let itemRepresentative = menuItemRepresentatives[index] {
			return itemRepresentative
		}
		
		return nil
	}
}
