//
//  SystemDirectory.swift
//  BurntFoundation
//
//  Created by Patrick Smith on 26/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation



public class SystemDirectory {
	public typealias ErrorReceiver = (NSError) -> ()
	
	public let pathComponents: [String]
	public let domainMask: FileManager.SearchPathDomainMask
	public let directoryBase: FileManager.SearchPathDirectory
	public let errorReceiver: ErrorReceiver
	fileprivate let group: DispatchGroup
	fileprivate var createdDirectoryURL: URL?
	
	public init(pathComponents: [String], inUserDirectory directoryBase: FileManager.SearchPathDirectory, errorReceiver: @escaping ErrorReceiver, useBundleIdentifier: Bool = true) {
		var pathComponents = pathComponents
		if useBundleIdentifier {
			if let bundleIdentifier = Bundle.main.bundleIdentifier {
				pathComponents.insert(bundleIdentifier, at: 0)
			}
		}
		
		self.pathComponents = pathComponents
		self.domainMask = [.userDomainMask]
		self.directoryBase = directoryBase
		self.errorReceiver = errorReceiver
		
		group = DispatchGroup()
		
		createDirectory()
	}
	
	fileprivate func createDirectory() {
		let queue = DispatchQueue.global(qos: .default)
		queue.async(group: group) {
			let fm = FileManager.default
			
			do {
				let baseDirectoryURL = try fm.url(for: self.directoryBase, in: self.domainMask, appropriateFor: nil, create: true)
				
				// Convert path to its components, so we can add more components
				// and convert back into a URL.
				var pathComponents = baseDirectoryURL.pathComponents
				pathComponents.append(contentsOf: self.pathComponents)
				
				// Convert components back into a URL.
				guard let directoryURL = NSURL.fileURL(withPathComponents: pathComponents)
          else { return }
				
				try fm.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
				
				self.createdDirectoryURL = directoryURL
			}
			catch let error as NSError {
				self.errorReceiver(error)
			}
		}
	}
	
	public func useOnQueue(_ queue: DispatchQueue, closure: @escaping (_ directoryURL: URL) -> ()) {
		group.notify(queue: queue) {
			if let createdDirectoryURL = self.createdDirectoryURL {
				closure(createdDirectoryURL)
			}
		}
	}
}
