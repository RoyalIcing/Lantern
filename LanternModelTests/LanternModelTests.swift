//
//	LanternModelTests.swift
//	LanternModelTests
//
//	Created by Patrick Smith on 30/03/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import XCTest
import LanternModel

class LanternModelTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testDetectWebURL() {
		XCTAssertEqual(detectWebURL(fromString: "https://www.burntcaramel.com/"), URL(string: "https://www.burntcaramel.com/"))
		
		XCTAssertEqual(detectWebURL(fromString: "https://www.burntcaramel.com"), URL(string: "https://www.burntcaramel.com"))
		
		XCTAssertEqual(detectWebURL(fromString: "www.burntcaramel.com"), URL(string: "http://www.burntcaramel.com"))
		
		XCTAssertEqual(detectWebURL(fromString: "burntcaramel.com"), URL(string: "http://burntcaramel.com"))
	}
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measure() {
			// Put the code you want to measure the time of here.
		}
	}
	
}
