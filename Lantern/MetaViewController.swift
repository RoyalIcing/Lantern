//
//  MetaViewController.swift
//  Lantern
//
//  Created by Patrick Smith on 1/11/16.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa
//import LanternModel
//import Ono


class MetaViewController : NSViewController {
	//@IBOutlet var stackView: NSStackView!
	@IBOutlet var tableView: NSTableView!
	
	var crawlerProviderListenerUUID = UUID()

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		
		tableView.dataSource = self
		tableView.delegate = self
		
		if let provider = pageMapperProvider {
			let crawlerProviderListenerUUID = self.crawlerProviderListenerUUID
			
			provider[activeURLChangedCallback: crawlerProviderListenerUUID] = { [weak self] url in
				self?.updateUI(url: url)
			}
			
			provider[pageMapperCreatedCallback: crawlerProviderListenerUUID] = { [weak self] pageMapper in
				pageMapper[didUpdateCallback: crawlerProviderListenerUUID] = { [weak self] url in
					if url == provider.activeURL {
						self?.updateUI(url: url)
					}
				}
			}
			
			updateUI(url: provider.activeURL)
		}
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		
		guard let provider = pageMapperProvider else { return }
		
		provider[activeURLChangedCallback: crawlerProviderListenerUUID] = nil
	}
	
	/*func createStackViews(_ url: URL?) -> [NSView] {
		guard let url = url else {
			return []
		}
		
		if let crawler = pageMapperProvider?.pageMapper {
			if
				let resourceInfo = crawler.pageInfoForRequestedURL(url),
				let contentInfo = resourceInfo.contentInfo
			{
				let metaTagFields: [NSTextField] = contentInfo.metaElementAttributes.map { attributes in
					print(attributes)
					let textField = NSTextField(string: "\(attributes)")
					textField.translatesAutoresizingMaskIntoConstraints = false
					textField.setContentCompressionResistancePriority(NSLayoutPriorityDefaultHigh, for: .horizontal)
					return textField
				}
				
				print("metaTagFields \(metaTagFields)")
				
				return Array([
					metaTagFields
				].joined())
			}
		}
		
		return [
			NSTextField(labelWithString: "Loading…"),
		]
	}*/
	
	func findMetaElementAttributes(url: URL) -> [[String : String]]? {
		guard
			let crawler = pageMapperProvider?.pageMapper,
			let resourceInfo = crawler.pageInfoForRequestedURL(url),
			let contentInfo = resourceInfo.contentInfo
			else { return nil }
		
		return contentInfo.metaElementAttributes
	}
	
	var metaElementAttributes: [[String : String]] = []
	
	func updateUI(url: URL?) {
		metaElementAttributes = url.flatMap{ findMetaElementAttributes(url: $0) } ?? []
		tableView.reloadData()
		//stackView.setViews(createStackViews(url), in: NSStackViewGravity.center)
	}
}

extension MetaViewController : NSTableViewDataSource, NSTableViewDelegate {
	func numberOfRows(in tableView: NSTableView) -> Int {
		return metaElementAttributes.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let attributes = metaElementAttributes[row]
		let identifier = convertFromNSUserInterfaceItemIdentifier(tableColumn!.identifier)
		let view = tableView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier(identifier), owner: self) as! NSTableCellView
		
		var property = attributes["name"] ?? attributes["property"] ?? attributes["http-equiv"]
		var contentAttributeKey = "content"
		if property == nil && attributes["charset"] != nil {
			property = "charset"
			contentAttributeKey = "charset"
		}
		
		switch identifier {
		case "property":
			view.textField?.stringValue = property ?? attributes.keys.filter{ $0 != "content" }.joined(separator: " ")
		case "value":
			view.textField?.stringValue = attributes[contentAttributeKey] ?? "?"
		default:
			break
		}
		
		return view
	}
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSUserInterfaceItemIdentifier(_ input: NSUserInterfaceItemIdentifier) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSUserInterfaceItemIdentifier(_ input: String) -> NSUserInterfaceItemIdentifier {
	return NSUserInterfaceItemIdentifier(rawValue: input)
}
