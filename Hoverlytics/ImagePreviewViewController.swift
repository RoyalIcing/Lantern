//
//  ImagePreviewViewController.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 4/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class ImagePreviewViewController: NSViewController {
	@IBOutlet var imageView: NSImageView!
	@IBOutlet var MIMETypeField: NSTextField!
	@IBOutlet var pixelWidthField: NSTextField!
	@IBOutlet var pixelHeightField: NSTextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.appearance = NSAppearance(named: NSAppearanceNameAqua)
		
		imageView.action = "clickedImageView:"
		imageView.target = self
		//imageView.ignoresMultiClick = true
		
		createMenu()
	}
	
	func createMenu() {
		let menu = NSMenu(title: "Values Menu")
		
		let copyImageItem = menu.addItemWithTitle("Copy Image", action: "copyImage:", keyEquivalent: "")!
		copyImageItem.target = self
		
		imageView.menu = menu
	}
	
	var sourceURL: NSURL? {
		didSet {
			if let sourceURL = sourceURL {
				title = sourceURL.absoluteString
			}
		}
	}
	
	var image: NSImage? {
		didSet {
			imageView.image = image
			
			if let image = image {
				let size = image.size
				pixelWidthField.integerValue = Int(size.width)
				pixelHeightField.integerValue = Int(size.height)
			}
			else {
				pixelWidthField.stringValue = ""
				pixelHeightField.stringValue = ""
			}
		}
	}
	
	var imageData: NSData! {
		didSet {
			if let image = NSImage(data: imageData) {
				self.image = image
			}
			else {
				self.image = nil
			}
		}
	}
	
	var MIMEType: String? {
		didSet {
			MIMETypeField.stringValue = MIMEType ?? ""
		}
	}
	
	class func instantiateFromStoryboard() -> ImagePreviewViewController {
		let vc =  NSStoryboard.lantern_contentPreviewStoryboard.instantiateControllerWithIdentifier("Image View Controller") as! ImagePreviewViewController
		let view = vc.view // Stupid NSViewController
		return vc
	}
}

extension ImagePreviewViewController {
	@IBAction func copyImage(sender: AnyObject?) {
		performCopyImage()
	}
	
	func performCopyImage() {
		if let image = image {
			let pasteboard = NSPasteboard.generalPasteboard()
			pasteboard.clearContents()
			
			if
				let imageData = imageData,
				let MIMEType = MIMEType where MIMEType != "",
				let UTIs = UTTypeCreateAllIdentifiersForTag(kUTTagClassMIMEType, MIMEType, kUTTypeImage)?.takeRetainedValue() as? [String]//,
				//let pasteboardType = UTTypeCopyPreferredTagWithClass(preferredUTI, kUTTagClassNSPboardType).takeRetainedValue()
			{
				pasteboard.declareTypes(UTIs, owner: nil)
				for UTI in UTIs {
					pasteboard.setData(imageData, forType: UTI)
				}
			}
			else {
				pasteboard.writeObjects([image])
			}
		}
	}
	
	@IBAction func clickedImageView(sender: AnyObject?) {
		dismissController(sender)
	}
	
	override var acceptsFirstResponder: Bool {
		return true
	}
	
	override func cancelOperation(sender: AnyObject?) {
		dismissController(sender)
	}
	
	/*
	override func mouseUp(theEvent: NSEvent) {
		dismissController(nil)
	}
	*/
	
	override func keyDown(theEvent: NSEvent) {
		if let charactersIgnoringModifiers = theEvent.charactersIgnoringModifiers {
			let u = charactersIgnoringModifiers[charactersIgnoringModifiers.startIndex]
			
			// Just like QuickLook, use space to dismiss.
			if u == Character(" ") {
				dismissController(nil)
			}
		}
	}
}

extension ImagePreviewViewController: NSPopoverDelegate {
	func popoverDidShow(notification: NSNotification) {
		if let window = view.window {
			window.makeFirstResponder(self)
		}
		
		view.layoutSubtreeIfNeeded()
	}
	
	func popoverShouldDetach(popover: NSPopover) -> Bool {
		return true
	}
}
