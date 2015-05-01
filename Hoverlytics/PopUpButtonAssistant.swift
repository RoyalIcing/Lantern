//
//  PopUpButtonAssistant.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 2/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


// Uses MenuAssistant’s MenuItemRepresentative protocol

public class PopUpButtonAssistant<T: MenuItemRepresentative> {
	public let popUpButton: NSPopUpButton
	public let menuAssistant: MenuAssistant<T>
	
	public init(popUpButton: NSPopUpButton) {
		self.popUpButton = popUpButton
		menuAssistant = MenuAssistant<T>(menu: popUpButton.menu)
	}
	
	public typealias ItemUniqueIdentifier = T.UniqueIdentifier
	
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
	
	public func itemRepresentativeForMenuItemAtIndex(menuItemIndex: Int) -> T? {
		return menuItemRepresentatives[menuItemIndex]
	}
	
	public func uniqueIdentifierForMenuItemAtIndex(menuItemIndex: Int) -> ItemUniqueIdentifier? {
		return itemRepresentativeForMenuItemAtIndex(menuItemIndex)?.uniqueIdentifier
	}
	
	var selectedItemRepresentative: T? {
		get {
			let index = popUpButton.indexOfSelectedItem
			if index != -1 {
				return itemRepresentativeForMenuItemAtIndex(index)
			}
			
			return nil
		}
		set(newItemRepresentative) {
			selectedUniqueIdentifier = newItemRepresentative?.uniqueIdentifier
		}
	}
	
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
