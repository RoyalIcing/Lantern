//
//	MultipleStringPreviewViewController.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 3/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import LanternModel


class MultipleStringPreviewViewController: NSViewController {
	@IBOutlet var tableView: NSTableView!
	var measuringTableCellView: MultipleStringPreviewTableCellView!
	
	var itemMenu: NSMenu!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.dataSource = self
		tableView.delegate = self
		
		measuringTableCellView = tableView.make(withIdentifier: "stringValue", owner: self) as! MultipleStringPreviewTableCellView
		
		view.appearance = NSAppearance(named: NSAppearanceNameAqua)
	}
	
	func createRowMenu() {
		// Row Menu
		itemMenu = NSMenu(title: "Values Menu")
		
		let copyValueItem = itemMenu.addItem(withTitle: "Copy Value", action: #selector(MultipleStringPreviewViewController.copyValueForSelectedRow(_:)), keyEquivalent: "")
		copyValueItem.target = self
	}
	
	var validatedStringValues: [ValidatedStringValue] = [] {
		didSet {
			reloadValues()
		}
	}
	
	func reloadValues() {
		// Stupid NSViewController
		_ = self.view
		
		tableView.reloadData()
	}
	
	override func keyDown(with theEvent: NSEvent) {
		if theEvent.burnt_isSpaceKey {
			// Just like QuickLook, use space to dismiss.
			dismiss(nil)
		}
	}
}

extension MultipleStringPreviewViewController {
	class func instantiateFromStoryboard() -> MultipleStringPreviewViewController {
		return NSStoryboard.lantern_contentPreviewStoryboard.instantiateController(withIdentifier: "String Value View Controller") as! MultipleStringPreviewViewController
	}
}

extension MultipleStringPreviewViewController {
	@IBAction func copyValueForSelectedRow(_ menuItem: NSMenuItem) {
		let row = tableView.clickedRow
		if row != -1 {
			performCopyValueForItemAtRow(row)
		}
	}
	
	func performCopyValueForItemAtRow(_ row: Int) {
		switch validatedStringValues[row] {
		case .validString(let stringValue):
			let pasteboard = NSPasteboard.general()
			pasteboard.clearContents()

			pasteboard.declareTypes([NSStringPboardType], owner: nil)
			pasteboard.setString(stringValue, forType: NSStringPboardType)
		default:
			break
		}
	}
}

extension MultipleStringPreviewViewController: NSTableViewDataSource, NSTableViewDelegate {
	func numberOfRows(in tableView: NSTableView) -> Int {
		return validatedStringValues.count
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		switch validatedStringValues[row] {
		case .validString(let stringValue):
			return stringValue
		default:
			break
		}
		
		return nil
	}
	
	func setUpTableCellView(_ view: MultipleStringPreviewTableCellView, tableColumn: NSTableColumn?, row: Int, visualsAndInteraction: Bool = true) {
		let validatedStringValue = validatedStringValues[row]
		
		let textField = view.textField!
		textField.stringValue = validatedStringValue.stringValueForPresentation
		
		let indexField = view.indexField!
		indexField.stringValue = String(row + 1) // 1-based index
		
		if visualsAndInteraction {
			let textColor = NSColor.textColor
			
			indexField.textColor = textColor.withAlphaComponent(0.3)
			
			textField.textColor = textColor.withAlphaComponent(validatedStringValue.alphaValueForPresentation)
			
			view.menu = itemMenu
		}
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		let cellView = measuringTableCellView
		
		setUpTableCellView(cellView!, tableColumn: nil, row: row, visualsAndInteraction: false)
		
		let tableColumn = tableView.tableColumns[0] 
		let cellWidth = tableColumn.width
		cellView?.setFrameSize(NSSize(width: cellWidth, height: 100.0))
		cellView?.layoutSubtreeIfNeeded()
		
		let textField = cellView?.textField!
		textField?.preferredMaxLayoutWidth = (textField?.bounds.width)!
		
		let extraPadding: CGFloat = 5.0 + 5.0
		
		let height = (textField?.intrinsicContentSize.height)! + extraPadding
		
		return height
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		if let view = tableView.make(withIdentifier: "stringValue", owner: self) as? MultipleStringPreviewTableCellView {
			setUpTableCellView(view, tableColumn: tableColumn, row: row)
			
			return view
		}
		
		return nil
	}
	
	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		return false
	}
}

extension MultipleStringPreviewViewController: NSPopoverDelegate {
	func popoverWillShow(_ notification: Notification) {
		//let popover = notification.object as! NSPopover
		//popover.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
		//popover.appearance = NSAppearance(named: NSAppearanceNameLightContent)
		//popover.appearance = .HUD
	}
}


class MultipleStringPreviewTableCellView: NSTableCellView {
	@IBOutlet var indexField: NSTextField!
}
