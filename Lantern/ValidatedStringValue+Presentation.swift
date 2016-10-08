//
//	ValidatedStringValue+Presentation.swift
//	Hoverlytics
//
//	Created by Patrick Smith on 3/05/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import LanternModel


extension ValidatedStringValue {
	static var loadingAlphaValueForPresentation: CGFloat = 0.2
	
	var alphaValueForPresentation: CGFloat {
		switch self {
		case .validString:
			return 1.0
		default:
			return 0.3
		}
	}
	
	var stringValueForPresentation: String {
		switch self {
		case .validString(let stringValue):
			return stringValue
		case .notRequested:
			return "(not requested)"
		case .missing:
			return "(none)"
		case .empty:
			return "(empty)"
		case .multiple:
			return "(multiple)"
		case .invalid:
			return "(invalid)"
		}
	}
}
