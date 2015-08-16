//
//  UniqueURLArray.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


func conformURL(URL: NSURL, requireHost: Bool = true) -> NSURL? {
	if let URLComponents = NSURLComponents(URL: URL, resolvingAgainstBaseURL: true) {
		if requireHost && URLComponents.host == nil {
			return nil
		}
		// Remove #fragments
		URLComponents.fragment = nil
		// Home page should always have trailing slash
		if URLComponents.path == "" {
			URLComponents.path = "/"
		}
		// Return adjusted URL
		return URLComponents.URL
	}
	else {
		return nil
	}
}


class UniqueURLArray: SequenceType {
	private var uniqueURLs = Set<NSURL>()
	var orderedURLs = [NSURL]()
	
	typealias Generator = Array<NSURL>.Generator
	func generate() -> Generator {
		return orderedURLs.generate()
	}
	
	typealias Index = Array<NSURL>.Index
	subscript(position: Index) -> Generator.Element {
		return orderedURLs[position]
	}
	
	var count: Int {
		return uniqueURLs.count
	}
	
	func contains(URL: NSURL) -> Bool {
		if let URL = conformURL(URL) {
			return uniqueURLs.contains(URL)
		}
		
		return false
	}
	
	func insertReturningConformedURLIfNew(var URL: NSURL) -> NSURL? {
		if let URL = conformURL(URL) {
			if !uniqueURLs.contains(URL) {
				uniqueURLs.insert(URL)
				orderedURLs.append(URL)
				return URL
			}
		}
		
		return nil
	}
	
	func remove(URL: NSURL) {
		if let URL = conformURL(URL) {
			if let setIndex = uniqueURLs.indexOf(URL) {
				uniqueURLs.removeAtIndex(setIndex)
				
				if let arrayIndex = find(orderedURLs, URL) {
					orderedURLs.removeAtIndex(arrayIndex)
				}
			}
		}
	}
	
	func removeAll() {
		uniqueURLs.removeAll()
		orderedURLs.removeAll()
	}
}

extension UniqueURLArray: Printable {
	var description: String {
		return uniqueURLs.description
	}
}
