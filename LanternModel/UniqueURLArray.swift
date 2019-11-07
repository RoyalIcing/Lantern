//
//	UniqueURLArray.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 28/04/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


func conformURL(_ URL: Foundation.URL, requireHost: Bool = true) -> Foundation.URL? {
	if var urlComponents = URLComponents(url: URL, resolvingAgainstBaseURL: true) {
		if requireHost && urlComponents.host == nil {
			return nil
		}
		// Remove #fragments
		urlComponents.fragment = nil
		// Home page should always have trailing slash
		if urlComponents.path == "" {
			urlComponents.path = "/"
		}
		// Return adjusted URL
		return urlComponents.url
	}
	else {
		return nil
	}
}


class UniqueURLArray: Sequence {
	fileprivate var uniqueURLs = Set<URL>()
	var orderedURLs = [URL]()
	
	typealias Iterator = Array<URL>.Iterator
	func makeIterator() -> Iterator {
		return orderedURLs.makeIterator()
	}
	
	typealias Index = Array<URL>.Index
	subscript(position: Index) -> Iterator.Element {
		return orderedURLs[position]
	}
	
	var count: Int {
		return uniqueURLs.count
	}
	
	func contains(_ URL: Foundation.URL) -> Bool {
		if let URL = conformURL(URL) {
			return uniqueURLs.contains(URL)
		}
		
		return false
	}
	
	func insertReturningConformedURLIfNew(_ URL: Foundation.URL) -> Foundation.URL? {
		if let URL = conformURL(URL) {
			if !uniqueURLs.contains(URL) {
				uniqueURLs.insert(URL)
				orderedURLs.append(URL)
				return URL
			}
		}
		
		return nil
	}
	
	func remove(_ URL: Foundation.URL) {
		if let URL = conformURL(URL) {
			if let setIndex = uniqueURLs.firstIndex(of: URL) {
				uniqueURLs.remove(at: setIndex)
				
				if let arrayIndex = orderedURLs.firstIndex(of: URL) {
					orderedURLs.remove(at: arrayIndex)
				}
			}
		}
	}
	
	func removeAll() {
		uniqueURLs.removeAll()
		orderedURLs.removeAll()
	}
}

extension UniqueURLArray: CustomStringConvertible {
	var description: String {
		return uniqueURLs.description
	}
}
