//
//	TableCellView.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 4/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


// An extension lets us both subclass NSTableView and NSOutlineView with the same functionality
extension NSTableView {
	// Find a cell view, or a row view, that has a menu. (e.g. NSResponder’s menu: NSMenu?)
	func burnt_menuForEventFromCellOrRowViews(_ event: NSEvent) -> NSMenu? {
		let point = convert(event.locationInWindow, from: nil)
		let row = self.row(at: point)
		if row != -1 {
			if let rowView = rowView(atRow: row, makeIfNecessary: true) {
				let column = self.column(at: point)
				if column != -1 {
					if let cellView = rowView.view(atColumn: column) as? NSTableCellView {
						if let cellMenu = cellView.menu(for: event) {
							return cellMenu
						}
					}
				}
				
				if let rowMenu = rowView.menu(for: event) {
					return rowMenu
				}
			}
		}
		
		return nil
	}
}


class OutlineView: NSOutlineView {
	override func menu(for event: NSEvent) -> NSMenu? {
		// Because of weird NSTableView/NSOutlineView behaviour, must set receiver’s menu otherwise the target cannot be found
		self.menu = burnt_menuForEventFromCellOrRowViews(event)
		
		return super.menu(for: event)
	}
}

class TableView: NSTableView {
	override func menu(for event: NSEvent) -> NSMenu? {
		// Because of weird NSTableView/NSOutlineView behaviour, must set receiver’s menu otherwise the target cannot be found
		self.menu = burnt_menuForEventFromCellOrRowViews(event)
		
		return super.menu(for: event)
	}
}
