//
//	ContentPreview.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 3/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


// Globals are lazy in Swift
var contentPreviewStoryboard: NSStoryboard = NSStoryboard(name: "ContentPreview", bundle: nil)

extension NSStoryboard {
	class var lantern_contentPreviewStoryboard: NSStoryboard {
		return contentPreviewStoryboard
	}
}
