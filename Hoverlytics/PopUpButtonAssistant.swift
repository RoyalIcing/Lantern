//
//  PopUpButtonAssistant.swift
//  BurntCocoaUI
//
//  Created by Patrick Smith on 2/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


// Uses MenuAssistant’s MenuItemRepresentative protocol

public class PopUpButtonAssistant<T: MenuItemRepresentative> {
	public typealias Item = T
	public typealias ItemUniqueIdentifier = Item.UniqueIdentifier
	
	public let popUpButton: NSPopUpButton
	public let menuAssistant: MenuAssistant<Item>
	
	public init(popUpButton: NSPopUpButton) {
		self.popUpButton = popUpButton
		menuAssistant = MenuAssistant<Item>(menu: popUpButton.menu!)
	}
	
	/**
	Pass an array of item representatives for each menu item. Use nil for separators.
	*/
	public var menuItemRepresentatives: [Item?]! {
		get {
			return menuAssistant.menuItemRepresentatives
		}
		set {
			menuAssistant.menuItemRepresentatives = newValue
		}
	}
	
	/**
	Populates the menu of the pop-up button with menu items created for each member of `menuItemRepresentatives`. The selected item will remain selected if its menu item is still present after updating.
	*/
	public func update() {
		// Get current selected item
		let selectedItem = popUpButton.selectedItem
		
		menuAssistant.update()
		
		// Restore selected item
		if let selectedItem = selectedItem {
			let selectedItemIndex = popUpButton.indexOfItem(selectedItem)
			if selectedItemIndex != -1 {
				popUpButton.selectItemAtIndex(selectedItemIndex)
			}
		}
	}
	
	/**
	The item representative for the selected menu item, or nil if no menu item is selected.
	*/
	var selectedItemRepresentative: Item? {
		get {
			let index = popUpButton.indexOfSelectedItem
			if index != -1 {
				return menuAssistant.itemRepresentativeForMenuItemAtIndex(index)
			}
			
			return nil
		}
	}
	
	/**
	The unique identifier for the selected menu item, or nil if no menu item is selected.
	*/
	var selectedUniqueIdentifier: ItemUniqueIdentifier? {
		get {
			return selectedItemRepresentative?.uniqueIdentifier
		}
		set(newIdentifier) {
			if let newIdentifier = newIdentifier {
				for (index, itemRepresentative) in enumerate(menuItemRepresentatives) {
					if itemRepresentative?.uniqueIdentifier == newIdentifier {
						popUpButton.selectItemAtIndex(index)
						return
					}
				}
			}
			
			popUpButton.selectItem(nil)
		}
	}
}
