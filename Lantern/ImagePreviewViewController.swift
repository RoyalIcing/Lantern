//
//  ImagePreviewViewController.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 4/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import Quartz


class ImagePreviewViewController: NSViewController {
	@IBOutlet var MIMETypeField: NSTextField!
	@IBOutlet var pixelWidthField: NSTextField!
	@IBOutlet var pixelHeightField: NSTextField!
	var innerImageViewController: ImagePreviewInnerViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.appearance = NSAppearance(named: NSAppearanceNameAqua)
	}
	
	override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "imageViewController" {
			let innerImageViewController = segue.destinationController as! ImagePreviewInnerViewController
			
			innerImageViewController.imageData = imageData
			
			innerImageViewController.wantsToDismiss = {
				self.dismissController(nil)
			}
			
			innerImageViewController.imagePropertiesDidLoad = { [weak self] imageProperties in
				if let
					receiver = self,
					pixelWidthNumber = imageProperties[kCGImagePropertyPixelWidth] as? NSNumber,
					pixelHeightNumber = imageProperties[kCGImagePropertyPixelHeight] as? NSNumber
				{
					receiver.pixelWidthField.integerValue = pixelWidthNumber.integerValue
					receiver.pixelHeightField.integerValue = pixelHeightNumber.integerValue
				}

			}
			
			self.innerImageViewController = innerImageViewController
		}
	}
	
	func resetUI()
	{
		pixelWidthField.stringValue = ""
		pixelHeightField.stringValue = ""
	}
	
	var sourceURL: NSURL? {
		didSet {
			if let sourceURL = sourceURL {
				title = sourceURL.absoluteString
			}
		}
	}
	
	var imageData: NSData! {
		didSet {
			resetUI()
			
			innerImageViewController?.imageData = imageData
		}
	}
	
	var MIMEType: String? {
		didSet {
			MIMETypeField.stringValue = MIMEType ?? ""
		}
	}
	
	var contentSizeConstraints = [NSLayoutConstraint]()
	var superviewSizeConstraints = [NSLayoutConstraint]()
	//var screenWidthConstraint
	
	#if false
	override func updateViewConstraints() {
		/*if let screen = view.window?.screen {
			let size = screen.visibleFrame.size
			
		}*/
		let view = self.view
		let imageView = self.imageView
		//if let windowContentView = view.window?.contentView as? NSView {
		if let window = view.window, screen = window.screen {
			if self.contentSizeConstraints.count > 0 {
				view.removeConstraints(self.contentSizeConstraints)
			}
			
			func layoutConstraintWithView(view: NSView, #attribute: NSLayoutAttribute, #relatedBy: NSLayoutRelation, #constant: CGFloat) -> NSLayoutConstraint {
				let constraint = NSLayoutConstraint(item: imageView, attribute: attribute, relatedBy: relatedBy, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: constant)
				return constraint
			}
			
			let imageSize = imageView.imageSize()
			let screenSize = screen.visibleFrame.size
			let windowSize = window.frame.size
			let maximumSize = NSSize(
				width: min(screenSize.width, windowSize.width),
				height: min(screenSize.height, windowSize.height)
			)
	
			let contentSizeConstraints = [
				//layoutConstraintWithView(imageView, attribute: .Width, relatedBy: .GreaterThanOrEqual, constant: imageSize.width, required: false),
				//layoutConstraintWithView(imageView, attribute: .Height, relatedBy: .GreaterThanOrEqual, constant: imageSize.height, required: false),
				layoutConstraintWithView(imageView, attribute: .Width, relatedBy: .LessThanOrEqual, constant: maximumSize.width),
				layoutConstraintWithView(imageView, attribute: .Height, relatedBy: .LessThanOrEqual, constant: maximumSize.width)
			]
			
			view.addConstraints(contentSizeConstraints)
			
			self.contentSizeConstraints = contentSizeConstraints
			
			#if false
			if let superview = view.superview {
				let superviewSizeConstraints = [
					layoutConstraintWithView(view, attribute: .Width, relatedBy: .LessThanOrEqual, constant: maximumSize.width),
					layoutConstraintWithView(view, attribute: .Height, relatedBy: .LessThanOrEqual, constant: maximumSize.width),
					NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .LessThanOrEqual, toItem: superview, attribute: .Width, multiplier: 1.0, constant: 0.0),
					NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .LessThanOrEqual, toItem: superview, attribute: .Height, multiplier: 1.0, constant: 0.0),
				]
				
				superview.addConstraints(superviewSizeConstraints)
				
				self.superviewSizeConstraints = superviewSizeConstraints
			}
			else {
				self.superviewSizeConstraints.removeAll()
			}
			#endif
		}
		
		super.updateViewConstraints()
	}
	#endif
}

extension ImagePreviewViewController {
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
		if
			let imageData = imageData,
			let MIMEType = MIMEType where MIMEType != "",
			let UTIs = UTTypeCreateAllIdentifiersForTag(kUTTagClassMIMEType, MIMEType, kUTTypeImage)?.takeRetainedValue() as? [String]//,
			//let pasteboardType = UTTypeCopyPreferredTagWithClass(preferredUTI, kUTTagClassNSPboardType).takeRetainedValue()
		{
			let pasteboard = NSPasteboard.generalPasteboard()
			pasteboard.clearContents()
			
			pasteboard.declareTypes(UTIs, owner: nil)
			for UTI in UTIs {
				pasteboard.setData(imageData, forType: UTI)
			}
		}
	}
	
	override var acceptsFirstResponder: Bool {
		return true
	}
	
	override func cancelOperation(sender: AnyObject?) {
		dismissController(sender)
	}
	
	override func keyDown(theEvent: NSEvent) {
		if theEvent.burnt_isSpaceKey {
			// Just like QuickLook, use space to dismiss.
			dismissController(nil)
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


class ImagePreviewInnerViewController: NSViewController {
	@IBOutlet var imageView: IKImageView!
	
	var imagePropertiesDidLoad: ((imageProperties: [NSString: AnyObject]) -> Void)?
	var wantsToDismiss: (() -> Void)?
	
	var backgroundQueue: dispatch_queue_t!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		backgroundQueue = dispatch_queue_create("com.burntcaramel.ImagePreviewViewController.background", DISPATCH_QUEUE_SERIAL)
	}
	
	var coreGraphicsImageSource: CGImageSource!
	var viewedCoreGraphicsImage: CGImage?
	
	private func updateUIWithImage(image: CGImage, imageProperties: [NSString: AnyObject]?) {
		let view = self.view
		
		let imageView = self.imageView
		imageView.setImage(viewedCoreGraphicsImage, imageProperties: imageProperties)
		//imageView.zoomImageToActualSize(nil)
		
		var imageSize = imageView.imageSize()
		#if DEBUG
			println("imageSize \(imageSize)")
		#endif
		
		if var screenSize = view.window?.screen?.visibleFrame.size {
			#if DEBUG
				println("screenSize \(screenSize)")
			#endif
			screenSize.width -= 13.0 * 2.0 + 8.0
			screenSize.height -= 13.0 * 2.0 + 32.0
			//screenSize.height -= 32.0
			
			imageSize.width = min(imageSize.width, screenSize.width)
			imageSize.height = min(imageSize.height, screenSize.height)
		}
		
		//imageSize.width -= 13.0 * 2.0 + 8.0
		//imageSize.height -= 32.0
		
		#if DEBUG
			println("preferredContentSize \(imageSize)")
		#endif
		
		imageView.autoresizes = false
		preferredContentSize = imageSize
		
		if let imageProperties = imageProperties {
			imagePropertiesDidLoad?(imageProperties: imageProperties)
		}
		
		view.needsUpdateConstraints = true
		
		view.layoutSubtreeIfNeeded()
		
		//imageView.zoomImageToFit(nil)
		imageView.zoomImageToActualSize(nil)
		//view.superview
	}
	
	var imageData: NSData? {
		didSet {
			let view = self.view // Stupid NSViewController
			
			if let imageData = self.imageData {
				dispatch_async(backgroundQueue) {
					let coreGraphicsImageSource = CGImageSourceCreateWithData(imageData, nil)
					
					let viewedCoreGraphicsImage = CGImageSourceCreateImageAtIndex(coreGraphicsImageSource, 0, nil)
					let imageProperties = CGImageSourceCopyPropertiesAtIndex(coreGraphicsImageSource, 0, nil) as? [NSString: AnyObject]
					
					if let viewedCoreGraphicsImage = viewedCoreGraphicsImage {
						dispatch_async(dispatch_get_main_queue()) { [weak self] in
							self?.updateUIWithImage(viewedCoreGraphicsImage, imageProperties: imageProperties)
						}
					}
					
					self.viewedCoreGraphicsImage = viewedCoreGraphicsImage
					self.coreGraphicsImageSource = coreGraphicsImageSource
				}
			}
		}
	}
	
	@IBAction func clickedImageView(sender: AnyObject?) {
		wantsToDismiss?()
	}
	
	
	#if false
	func createMenu() {
		let menu = NSMenu(title: "Values Menu")
		
		let copyImageItem = menu.addItemWithTitle("Copy Image", action: "copyImage:", keyEquivalent: "")!
		copyImageItem.target = self
		
		imageView.menu = menu
	}
	#endif
}

