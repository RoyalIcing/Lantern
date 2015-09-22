//
//  TableCellView.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 4/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


// An extension lets us both subclass NSTableView and NSOutlineView with the same functionality
extension NSTableView {
	// Find a cell view, or a row view, that has a menu. (e.g. NSResponder’s menu: NSMenu?)
	func burnt_menuForEventFromCellOrRowViews(event: NSEvent) -> NSMenu? {
		let point = convertPoint(event.locationInWindow, fromView: nil)
		let row = rowAtPoint(point)
		if row != -1 {
			if let rowView = rowViewAtRow(row, makeIfNecessary: true) {
				let column = columnAtPoint(point)
				if column != -1 {
					if let cellView = rowView.viewAtColumn(column) as? NSTableCellView {
						if let cellMenu = cellView.menuForEvent(event) {
							return cellMenu
						}
					}
				}
				
				if let rowMenu = rowView.menuForEvent(event) {
					return rowMenu
				}
			}
		}
		
		return nil
	}
}


class OutlineView: NSOutlineView {
	override func menuForEvent(event: NSEvent) -> NSMenu? {
		// Because of weird NSTableView/NSOutlineView behaviour, must set receiver’s menu otherwise the target cannot be found
		self.menu = burnt_menuForEventFromCellOrRowViews(event)
		
		return super.menuForEvent(event)
	}
}

class TableView: NSTableView {
	override func menuForEvent(event: NSEvent) -> NSMenu? {
		// Because of weird NSTableView/NSOutlineView behaviour, must set receiver’s menu otherwise the target cannot be found
		self.menu = burnt_menuForEventFromCellOrRowViews(event)
		
		return super.menuForEvent(event)
	}
}
