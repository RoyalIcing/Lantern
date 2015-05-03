//
//  SourcePreviewViewController.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 27/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import HoverlyticsModel


enum SourcePreviewTabItemSection: String {
	case Main = "Main"
	case HTMLHead = "HTMLHead"
	case HTMLBody = "HTMLBody"
	
	var stringValue: String { return rawValue }
	
	func titleWithPageInfo(pageInfo: PageInfo) -> String {
		switch self {
		case .Main:
			if let MIMEType = pageInfo.MIMEType {
				return MIMEType.stringValue
			}
			else {
				return "Main"
			}
		case .HTMLHead:
			return "<head>"
		case .HTMLBody:
			return "<body>"
		}
	}
}


class SourcePreviewTabViewController: NSTabViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//tabView.delegate = self
	}
	
	var pageInfo: PageInfo! {
		didSet {
			switch pageInfo.baseContentType {
			case .LocalHTMLPage:
				updateForHTMLPreview()
			default:
				updateForGeneralPreview()
			}
		}
	}
	
	func updateWithSections(sections: [SourcePreviewTabItemSection]) {
		let tabViewItems = sections.map { section in
			self.newSourcePreviewTabViewItem(section: section)
		}
		
		// This crashes for some reason
		// self.tabViewItems = tabViewItems
		
		let existingItems = self.tabViewItems as! [NSTabViewItem]
		for existingItem in existingItems {
			removeTabViewItem(existingItem)
		}
		for tabViewItem in tabViewItems {
			addTabViewItem(tabViewItem)
		}
		
		//updateSourceTextForSection(sections[0], tabViewItem: tabViewItems[0])
	}
	
	func updateForGeneralPreview() {
		updateWithSections([.Main])
	}
	
	func updateForHTMLPreview() {
		updateWithSections([.HTMLHead, .HTMLBody])
	}
	
	func newSourcePreviewTabViewItem(#section: SourcePreviewTabItemSection) -> NSTabViewItem {
		let item = NSTabViewItem(identifier: section.stringValue)
		item.viewController = newSourcePreviewController()
		item.label = section.titleWithPageInfo(pageInfo)
		return item
	}
	
	lazy var sourcePreviewStoryboard: NSStoryboard = {
		NSStoryboard(name: "SourcePreview", bundle: nil)!
	}()
	
	func newSourcePreviewController() -> SourcePreviewViewController {
		return sourcePreviewStoryboard.instantiateControllerWithIdentifier("Source Preview View Controller") as! SourcePreviewViewController
	}
	
	func updateSourceTextForSection(section: SourcePreviewTabItemSection, tabViewItem: NSTabViewItem) {
		let vc = tabViewItem.viewController as! SourcePreviewViewController
		
		if let contentInfo = self.pageInfo.contentInfo {
			switch section {
			case .Main:
				setSourceText(contentInfo.stringContent, forSourcePreviewViewController: vc)
			case .HTMLHead:
				setSourceText(contentInfo.HTMLHeadStringContent, forSourcePreviewViewController: vc)
			case .HTMLBody:
				setSourceText(contentInfo.HTMLBodyStringContent, forSourcePreviewViewController: vc)
			}
		}
		else {
			setSourceText("(none)", forSourcePreviewViewController: vc)
		}
	}
	
	func setSourceText(sourceText: String?, forSourcePreviewViewController vc: SourcePreviewViewController) {
		vc.sourceText = sourceText ?? "(None)"
	}
	
	override func tabView(tabView: NSTabView, willSelectTabViewItem tabViewItem: NSTabViewItem) {
		if
			let identifier = tabViewItem.identifier as? String,
			let section = SourcePreviewTabItemSection(rawValue: identifier)
		{
			updateSourceTextForSection(section, tabViewItem: tabViewItem)
		}
	}
}

extension SourcePreviewTabViewController: NSPopoverDelegate {
	func popoverWillShow(notification: NSNotification) {
		let popover = notification.object as! NSPopover
		popover.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
		//popover.appearance = NSAppearance(named: NSAppearanceNameLightContent)
		//popover.appearance = .HUD
	}
}


class SourcePreviewViewController: NSViewController {
	
	@IBOutlet var textView: NSTextView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
	}
	
	let defaultTextAttributes: [NSObject: AnyObject] = [
		NSFontAttributeName: NSFont(name: "Menlo", size: 11.0)!,
		NSForegroundColorAttributeName: NSColor.highlightColor()
	]
	
	var sourceText: String! {
		didSet {
			let view = self.view // Make sure view has loaded
			
			if let textStorage = textView.textStorage {
				let attributes = defaultTextAttributes
				let newAttributedString = NSAttributedString(string: sourceText, attributes:attributes)
				textStorage.replaceCharactersInRange(NSMakeRange(0, textStorage.length), withAttributedString: newAttributedString)
			}
		}
	}
}
