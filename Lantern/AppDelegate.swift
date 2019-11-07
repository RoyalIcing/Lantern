//
//	AppDelegate.swift
//	Hoverlytics for Mac
//
//	Created by Patrick Smith on 28/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import LanternModel


let NSApp = NSApplication.shared

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var browserMenuController: BrowserMenuController!
	@IBOutlet var browserWidthPlaceholderMenuItem: NSMenuItem!
	
	var crawlerMenuController: CrawlerMenuController!
	@IBOutlet var crawlerImageDownloadPlaceholderMenuItem: NSMenuItem!
	
	
	deinit {
		let nc = NotificationCenter.default
		for observer in windowWillCloseObservers {
			nc.removeObserver(observer)
		}
		windowWillCloseObservers.removeAll()
	}

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Create shared manager to ensure quickest start up time.
		let modelManager = LanternModel.ModelManager.sharedManager
		modelManager.errorReceiver.errorCallback = { error in
			NSApp.presentError(error)
		}
		
		browserMenuController = BrowserMenuController(browserWidthPlaceholderMenuItem: browserWidthPlaceholderMenuItem)
		crawlerMenuController = CrawlerMenuController(imageDownloadPlaceholderMenuItem: crawlerImageDownloadPlaceholderMenuItem)
		
		#if DEBUG
			// Update the bloody Dock icon
			NSApp.applicationIconImage = nil
			
			UserDefaults.standard.set(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
		#endif
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	
	
	lazy var mainStoryboard: NSStoryboard = {
		return NSStoryboard(name: "Main", bundle: nil)
	}()
	
	var mainWindowControllers = [MainWindowController]()
	var windowWillCloseObservers = [AnyObject]()

	func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
		let windowController = mainStoryboard.instantiateInitialController() as! MainWindowController
		windowController.showWindow(nil)
		
		mainWindowControllers.append(windowController)
		
		let nc = NotificationCenter.default
		windowWillCloseObservers.append(nc.addObserver(forName: NSWindow.willCloseNotification, object: windowController.window!, queue: nil, using: { [unowned self] note in
			if let index = self.mainWindowControllers.firstIndex(of: windowController) {
				self.mainWindowControllers.remove(at: index)
			}
		}))
		
		return true
	}
	
	@IBAction func newDocument(_ sender: AnyObject?) {
		_ = self.applicationOpenUntitledFile(NSApp)
	}
	
	@IBAction func forkOnGitHub(_ sender: AnyObject?) {
		let URL = Foundation.URL(string: "https://github.com/BurntCaramel/Lantern")!
		NSWorkspace.shared.open(URL)
	}
}
