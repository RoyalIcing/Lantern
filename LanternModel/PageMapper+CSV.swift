//
//  PageMapper+CSV.swift
//  LanternModel
//
//  Created by Patrick Smith on 7/11/19.
//  Copyright © 2019 Burnt Caramel. All rights reserved.
//

import Foundation
import CSV

extension ValidatedStringValue {
	var stringForCSV: String {
		switch self {
		case .validString(let stringValue):
			return stringValue
		case .validKeyValue(let key, let value):
			return "\(key): \(value)"
		case .notRequested:
			return "(not requested)"
		case .missing:
			return "(none)"
		case .empty:
			return "(empty)"
		case .multiple(let values):
			return values.map { $0.stringForCSV }.joined(separator: "\t")
		case .invalid:
			return "(invalid)"
		}
	}
}


public struct CrawledResultsCSVCreator {
	public var baseContentType: BaseContentType = .localHTMLPage
	
	public init() {}
	
	public func csvData(pageMapper: PageMapper) throws -> Data {
		let csv = try CSVWriter(stream: .toMemory())
		
		let columnIdentifiers: [PagePresentedInfoIdentifier] = [.requestedURL, .pageTitle, .h1, .statusCode, .MIMEType, .pageByteCount, .pageByteCountBeforeBodyTag, .pageByteCountAfterBodyTag, .internalLinks, .externalLinks]
		try csv.write(row: ["path", "title", "h1", "status_code", "mime_type", "page_byte_count", "head_byte_count", "body_byte_count", "internal_links", "external_links"])
		
		let urls = pageMapper.copyURLsWithBaseContentType(baseContentType)
		for url in urls {
			if let resourceInfo = pageMapper.pageInfoForRequestedURL(url) {
				try csv.write(row: columnIdentifiers.map { identifier in
					identifier.validatedStringValueInPageInfo(resourceInfo, pageMapper: pageMapper).stringForCSV
				})
			}
		}
		
		csv.stream.close()
		
		return csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
	}
}

