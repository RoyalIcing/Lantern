//
//  SegmentedControlAssistant.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 29/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol SegmentedItemRepresentative {
	var title: String { get }
	var tag: Int? { get }
	
	typealias UniqueIdentifier: Hashable
	var uniqueIdentifier: UniqueIdentifier { get }
}


public class SegmentedControlAssistant<T: SegmentedItemRepresentative> {
	public let segmentedControl: NSSegmentedControl!
	public var segmentedCell: NSSegmentedCell! {
		return segmentedControl.cell() as? NSSegmentedCell
	}
	
	public typealias ItemUniqueIdentifier = T.UniqueIdentifier
	
	public init(segmentedControl: NSSegmentedControl) {
		self.segmentedControl = segmentedControl
	}
	
	
	var hasUpdatedBefore: Bool = false
	var previouslySelectedUniqueIdentifier: ItemUniqueIdentifier?
	
	public var segmentedItemRepresentatives: [T]! {
		willSet {
			if hasUpdatedBefore {
				previouslySelectedUniqueIdentifier = selectedUniqueIdentifier
			}
		}
	}
	
	public var titleReturner: ((segmentedItemRepresentative: T) -> String)?
	//public var selectedReturner: ((segmentedItemRepresentative: T) -> Bool)?
	//public var enabledReturner: ((segmentedItemRepresentative: T) -> Bool)?
	
	
	public func update() {
		let segmentedCell = self.segmentedCell
		let trackingMode = segmentedCell.trackingMode
		
		let segmentedItemRepresentatives = self.segmentedItemRepresentatives!
		
		// Update number of segments
		segmentedCell.segmentCount = segmentedItemRepresentatives.count
		
		// Update each segment from its corresponding representative
		var segmentIndex: Int = 0
		for segmentedItemRepresentative in segmentedItemRepresentatives {
			let title = self.titleReturner?(segmentedItemRepresentative: segmentedItemRepresentative) ?? segmentedItemRepresentative.title
			let tag = segmentedItemRepresentative.tag ?? 0
			
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
	
	
	public func itemRepresentativeForSegmentAtIndex(segmentIndex: Int) -> T {
		return segmentedItemRepresentatives[segmentIndex]
	}
	
	public func uniqueIdentifierForSegmentAtIndex(segmentIndex: Int) -> ItemUniqueIdentifier {
		return itemRepresentativeForSegmentAtIndex(segmentIndex).uniqueIdentifier
	}
	
	var selectedItemRepresentative: T? {
		get {
			let index = segmentedCell.selectedSegment
			if index != -1 {
				return itemRepresentativeForSegmentAtIndex(index)
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
