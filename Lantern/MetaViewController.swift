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
	@IBOutlet var stackView: NSStackView!
	
	var crawlerProviderListenerUUID = UUID()

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		
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
	
	func createStackViews(url: URL?) -> [NSView] {
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
	}
	
	func updateUI(url: URL?) {
		stackView.setViews(createStackViews(url: url), in: NSStackViewGravity.center)
	}
}
