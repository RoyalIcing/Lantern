//
//  MultipleStringPreviewViewController.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 3/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import HoverlyticsModel


class MultipleStringPreviewViewController: NSViewController {
	@IBOutlet var tableView: NSTableView!
	var measuringTableCellView: MultipleStringPreviewTableCellView!
	
	var itemMenu: NSMenu!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.setDataSource(self)
		tableView.setDelegate(self)
		
		measuringTableCellView = tableView.makeViewWithIdentifier("stringValue", owner: self) as! MultipleStringPreviewTableCellView
		
		tableView.appearance = NSAppearance(named: NSAppearanceNameAqua)
	}
	
	func createRowMenu() {
		// Row Menu
		itemMenu = NSMenu(title: "Values Menu")
		
		let copyValueItem = itemMenu.addItemWithTitle("Copy Value", action: "copyValueForSelectedRow:", keyEquivalent: "")!
		copyValueItem.target = self
	}
	
	var validatedStringValues: [ValidatedStringValue] = [] {
		didSet {
			reloadValues()
		}
	}
	
	func reloadValues() {
		// Stupid NSViewController
		let view = self.view
		
		tableView.reloadData()
	}
	
	class func instantiateFromStoryboard() -> MultipleStringPreviewViewController {
		return NSStoryboard.lantern_contentPreviewStoryboard.instantiateControllerWithIdentifier("String Value View Controller") as! MultipleStringPreviewViewController
	}
}

extension MultipleStringPreviewViewController {
	@IBAction func copyValueForSelectedRow(menuItem: NSMenuItem) {
		let row = tableView.clickedRow
		if row != -1 {
			performCopyValueForItemAtRow(row)
		}
	}
	
	func performCopyValueForItemAtRow(row: Int) {
		switch validatedStringValues[row] {
		case .ValidString(let stringValue):
			let pasteboard = NSPasteboard.generalPasteboard()
			pasteboard.clearContents()

			pasteboard.declareTypes([NSStringPboardType], owner: nil)
			pasteboard.setString(stringValue, forType: NSStringPboardType)
		default:
			break
		}
	}
}

extension MultipleStringPreviewViewController: NSTableViewDataSource, NSTableViewDelegate {
	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return validatedStringValues.count
	}
	
	func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
		switch validatedStringValues[row] {
		case .ValidString(let stringValue):
			return stringValue
		default:
			break
		}
		
		return nil
	}
	
	func setUpTableCellView(view: MultipleStringPreviewTableCellView, tableColumn: NSTableColumn?, row: Int, visualsAndInteraction: Bool = true) {
		let validatedStringValue = validatedStringValues[row]
		
		let textField = view.textField!
		textField.stringValue = validatedStringValue.stringValueForPresentation
		
		let indexField = view.indexField!
		indexField.stringValue = String(row + 1) // 1-based index
		
		if visualsAndInteraction {
			indexField.alphaValue = 0.3
			
			textField.alphaValue = validatedStringValue.alphaValueForPresentation
			
			view.menu = itemMenu
		}
	}
	
	func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		let cellView = measuringTableCellView
		
		setUpTableCellView(cellView, tableColumn: nil, row: row, visualsAndInteraction: false)
		
		let tableColumn = tableView.tableColumns[0] as! NSTableColumn
		let cellWidth = tableColumn.width
		cellView.setFrameSize(NSSize(width: cellWidth, height: 100.0))
		cellView.layoutSubtreeIfNeeded()
		
		let textField = cellView.textField!
		textField.preferredMaxLayoutWidth = textField.bounds.width
		
		let extraPadding: CGFloat = 5.0 + 5.0
		
		let height = textField.intrinsicContentSize.height + extraPadding
		
		return height
	}
	
	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		if let view = tableView.makeViewWithIdentifier("stringValue", owner: self) as? MultipleStringPreviewTableCellView {
			setUpTableCellView(view, tableColumn: tableColumn, row: row)
			
			return view
		}
		
		return nil
	}
	
	func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		return false
	}
}

extension MultipleStringPreviewViewController: NSPopoverDelegate {
	func popoverWillShow(notification: NSNotification) {
		let popover = notification.object as! NSPopover
		//popover.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
		//popover.appearance = NSAppearance(named: NSAppearanceNameLightContent)
		//popover.appearance = .HUD
	}
}


class MultipleStringPreviewTableCellView: NSTableCellView {
	@IBOutlet var indexField: NSTextField!
}
