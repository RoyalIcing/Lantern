//
//  SegmentedControlAssistant.swift
//  BurntCocoaUI
//
//  Created by Patrick Smith on 29/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


public protocol SegmentedItemRepresentative {
	var title: String { get }
	
	typealias UniqueIdentifier: Hashable
	var uniqueIdentifier: UniqueIdentifier { get }
}

public struct SegmentedItemCustomization<T: SegmentedItemRepresentative> {
	public typealias Item = T
	
	/**
	Customize the title dynamically, called for each segmented item representative.
	*/
	public var title: ((segmentedItemRepresentative: Item) -> String)?
	/**
	Customize the integer tag, called for each segemented item representative.
	*/
	public var tag: ((segmentedItemRepresentative: T) -> Int?)?
}


public class SegmentedControlAssistant<T: SegmentedItemRepresentative> {
	public typealias Item = T
	public typealias ItemUniqueIdentifier = Item.UniqueIdentifier
	
	public let segmentedControl: NSSegmentedControl!
	public var segmentedCell: NSSegmentedCell {
		return segmentedControl.cell() as! NSSegmentedCell
	}
	
	public init(segmentedControl: NSSegmentedControl) {
		self.segmentedControl = segmentedControl
	}
	
	/**
	Pass an array of item representatives for each segmented item.
	*/
	public var segmentedItemRepresentatives: [Item]! {
		willSet {
			if hasUpdatedBefore {
				previouslySelectedUniqueIdentifier = selectedUniqueIdentifier
			}
		}
	}
	
	/**
	Customize the segmented item’s title, tag with this.
	*/
	public var customization = SegmentedItemCustomization<Item>()
	
	private var hasUpdatedBefore: Bool = false
	private var previouslySelectedUniqueIdentifier: ItemUniqueIdentifier?
	
	/**
	Populates the segemented control with items created for each member of `segmentedItemRepresentatives`
	*/
	public func update() {
		let segmentedCell = self.segmentedCell
		let trackingMode = segmentedCell.trackingMode
		
		let segmentedItemRepresentatives = self.segmentedItemRepresentatives!
		
		// Update number of segments
		segmentedCell.segmentCount = segmentedItemRepresentatives.count
		
		let customization = self.customization
		
		// Update each segment from its corresponding representative
		var segmentIndex: Int = 0
		for segmentedItemRepresentative in segmentedItemRepresentatives {
			let title = customization.title?(segmentedItemRepresentative: segmentedItemRepresentative) ?? segmentedItemRepresentative.title
			let tag = customization.tag?(segmentedItemRepresentative: segmentedItemRepresentative) ?? 0
			
			segmentedCell.setLabel(title, forSegment: segmentIndex)
			segmentedCell.setTag(tag, forSegment: segmentIndex)
			
			segmentIndex++
		}
		
		if trackingMode == .SelectOne {
			self.selectedUniqueIdentifier = previouslySelectedUniqueIdentifier
		}
		
		hasUpdatedBefore = true
		previouslySelectedUniqueIdentifier = nil
	}
	
	/**
	Find the item representative for the passed segmented item index.
	
	:param: segmentIndex The index of the segmented item to find.
	
	:returns: The item representative that matched.
	*/
	public func itemRepresentativeForSegmentAtIndex(segmentIndex: Int) -> Item {
		return segmentedItemRepresentatives[segmentIndex]
	}
	
	/**
	Find the unique identifier for the passed segmented item index.
	
	:param: segmentIndex The index of the segmented item to find.
	
	:returns: The item representative that matched.
	*/
	public func uniqueIdentifierForSegmentAtIndex(segmentIndex: Int) -> ItemUniqueIdentifier {
		return itemRepresentativeForSegmentAtIndex(segmentIndex).uniqueIdentifier
	}
	
	/**
	The item representative for the selected segment, or nil if no segment is selected.
	*/
	var selectedItemRepresentative: Item? {
		get {
			let index = segmentedCell.selectedSegment
			if index != -1 {
				return itemRepresentativeForSegmentAtIndex(index)
			}
			
			return nil
		}
	}
	
	/**
	The unique identifier for the selected segment, or nil if no segment is selected.
	*/
	var selectedUniqueIdentifier: ItemUniqueIdentifier? {
		get {
			return selectedItemRepresentative?.uniqueIdentifier
		}
		set(newIdentifier) {
			if let newIdentifier = newIdentifier {
				for (index, itemRepresentative) in enumerate(segmentedItemRepresentatives) {
					if itemRepresentative.uniqueIdentifier == newIdentifier {
						segmentedControl.selectedSegment = index
						return
					}
				}
			}
			
			segmentedControl.selectedSegment = -1
		}
	}
}
