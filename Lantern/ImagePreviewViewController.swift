//
//	ImagePreviewViewController.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 4/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
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
	
	override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		if segue.identifier == "imageViewController" {
			let innerImageViewController = segue.destinationController as! ImagePreviewInnerViewController
			
			innerImageViewController.imageData = imageData
			
			innerImageViewController.wantsToDismiss = {
				self.dismiss(nil)
			}
			
			innerImageViewController.imagePropertiesDidLoad = { [weak self] imageProperties in
				if let
					receiver = self,
					let pixelWidthNumber = imageProperties[kCGImagePropertyPixelWidth] as? NSNumber,
					let pixelHeightNumber = imageProperties[kCGImagePropertyPixelHeight] as? NSNumber
				{
					receiver.pixelWidthField.integerValue = pixelWidthNumber.intValue
					receiver.pixelHeightField.integerValue = pixelHeightNumber.intValue
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
	
	var sourceURL: URL? {
		didSet {
			if let sourceURL = sourceURL {
				title = sourceURL.absoluteString
			}
		}
	}
	
	var imageData: Data! {
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
		if let window = view.window, let screen = window.screen {
			if self.contentSizeConstraints.count > 0 {
				view.removeConstraints(self.contentSizeConstraints)
			}
			
			func layoutConstraintWithView(view: NSView, attribute: NSLayoutAttribute, relatedBy: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
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
		let vc =	NSStoryboard.lantern_contentPreviewStoryboard.instantiateController(withIdentifier: "Image View Controller") as! ImagePreviewViewController
		_ = vc.view // Stupid NSViewController
		return vc
	}
}

extension ImagePreviewViewController {
	@IBAction func copyImage(_ sender: AnyObject?) {
		performCopyImage()
	}
	
	func performCopyImage() {
		if
			let imageData = imageData,
			let MIMEType = MIMEType , MIMEType != "",
			let UTIs = UTTypeCreateAllIdentifiersForTag(kUTTagClassMIMEType, MIMEType as CFString, kUTTypeImage)?.takeRetainedValue() as? [String]//,
			//let pasteboardType = UTTypeCopyPreferredTagWithClass(preferredUTI, kUTTagClassNSPboardType).takeRetainedValue()
		{
			let pasteboard = NSPasteboard.general()
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
	
	override func cancelOperation(_ sender: Any?) {
		dismiss(sender)
	}
	
	override func keyDown(with theEvent: NSEvent) {
		if theEvent.burnt_isSpaceKey {
			// Just like QuickLook, use space to dismiss.
			dismiss(nil)
		}
	}
}

extension ImagePreviewViewController: NSPopoverDelegate {
	func popoverDidShow(_ notification: Notification) {
		if let window = view.window {
			window.makeFirstResponder(self)
		}
		
		view.layoutSubtreeIfNeeded()
	}
	
	func popoverShouldDetach(_ popover: NSPopover) -> Bool {
		return true
	}
}


class ImagePreviewInnerViewController: NSViewController {
	@IBOutlet var imageView: IKImageView!
	
	var imagePropertiesDidLoad: ((_ imageProperties: [NSString: AnyObject]) -> Void)?
	var wantsToDismiss: (() -> Void)?
	
	var backgroundQueue: DispatchQueue!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		backgroundQueue = DispatchQueue(label: "com.burntcaramel.ImagePreviewViewController.background", attributes: [])
	}
	
	var coreGraphicsImageSource: CGImageSource!
	var viewedCoreGraphicsImage: CGImage?
	
	fileprivate func updateUIWithImage(_ image: CGImage, imageProperties: [NSString: AnyObject]?) {
		let view = self.view
		
		let imageView = self.imageView!
		imageView.setImage(viewedCoreGraphicsImage, imageProperties: imageProperties)
		//imageView.zoomImageToActualSize(nil)
		
		var imageSize = imageView.imageSize()
		#if DEBUG
			print("imageSize \(imageSize)")
		#endif
		
		if var screenSize = view.window?.screen?.visibleFrame.size {
			#if DEBUG
				print("screenSize \(screenSize)")
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
			print("preferredContentSize \(imageSize)")
		#endif
		
		imageView.autoresizes = false
		preferredContentSize = imageSize
		
		if let imageProperties = imageProperties {
			imagePropertiesDidLoad?(imageProperties)
		}
		
		view.needsUpdateConstraints = true
		
		view.layoutSubtreeIfNeeded()
		
		//imageView.zoomImageToFit(nil)
		imageView.zoomImageToActualSize(nil)
		//view.superview
	}
	
	var imageData: Data? {
		didSet {
			_ = self.view // Stupid NSViewController
			
			if let imageData = self.imageData {
				backgroundQueue.async {
					guard let coreGraphicsImageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return }
					
					let viewedCoreGraphicsImage = CGImageSourceCreateImageAtIndex(coreGraphicsImageSource, 0, nil)
					let imageProperties = CGImageSourceCopyPropertiesAtIndex(coreGraphicsImageSource, 0, nil) as? [NSString: AnyObject]
					
					if let viewedCoreGraphicsImage = viewedCoreGraphicsImage {
						DispatchQueue.main.async { [weak self] in
							self?.updateUIWithImage(viewedCoreGraphicsImage, imageProperties: imageProperties)
						}
					}
					
					self.viewedCoreGraphicsImage = viewedCoreGraphicsImage
					self.coreGraphicsImageSource = coreGraphicsImageSource
				}
			}
		}
	}
	
	@IBAction func clickedImageView(_ sender: AnyObject?) {
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

