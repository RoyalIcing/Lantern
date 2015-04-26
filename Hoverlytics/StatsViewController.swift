//
//  StatsViewController.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 24/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class StatsViewController: NSViewController {

	@IBOutlet var outlineView: NSOutlineView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		
		outlineView.setDataSource(self)
		outlineView.setDelegate(self)
    }
	
	var primaryURL: NSURL! {
		didSet {
			if let oldSiteMapper = siteMapper {
				siteMapper.cancel()
			}
			
			if let primaryURL = primaryURL {
				siteMapper = SiteMapper(primaryURL: primaryURL)
				siteMapper.didUpdateCallback = { loadedPageURL in
					println("DID LOAD STATS \(loadedPageURL)")
					self.pageURLDidUpdate(loadedPageURL)
				}
				
				siteMapper.reload()
				outlineView.reloadData()
			}
		}
	}
	
	var siteMapper: SiteMapper!
	
	func reload() {
		if let primaryURL = primaryURL {
			//siteMapper.reload()
		}
	}
	
	private func pageURLDidUpdate(pageURL: NSURL) {
		outlineView.reloadData()
		//outlineView.reloadItem(pageURL, reloadChildren: true)
	}
}

extension StatsViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
	func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		if item == nil {
			if let siteMapper = siteMapper {
				return siteMapper.localURLsOrdered.count
			}
		}
		
		return 0
	}
	
	func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		/*var orderedURLs = Array(siteMapper.localURLs)
		orderedURLs.sort { (URL1, URL2) -> Bool in
			
		}
		
		return orderedURLs[index]*/
		return siteMapper.localURLsOrdered[index]
	}
	
	func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		return false
	}
	
	func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
		return item
	}
	
	func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
		
		if
			let pageURL = item as? NSURL,
			let pageInfo = siteMapper.URLToPageInfo[pageURL],
			let identifier = tableColumn?.identifier,
			let view = outlineView.makeViewWithIdentifier(identifier, owner: self) as? NSTableCellView
		{
			let stringValue = { () -> String? in
				switch identifier {
				case "requestedURL":
					return pageInfo.requestedURL.relativePath
				case "pageTitle":
					return pageInfo.contentInfo.pageTitle
				case "h1":
					let h1Elements = pageInfo.contentInfo.h1Elements
					switch h1Elements.count {
					case 1:
						let stringValue = h1Elements[0].stringValue()
						return stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
					case 0:
						return "(none)"
					default:
						return "(multiple)"
					}
				default:
					return nil
				}
			}()
			view.textField?.stringValue = stringValue ?? "(unknown)"
			
			return view
		}
		else {
			return nil
		}
	}
}
