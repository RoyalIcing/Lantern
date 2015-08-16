//
//  ValidatedStringValue+Presentation.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 3/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import LanternModel


extension ValidatedStringValue {
	static var loadingAlphaValueForPresentation: CGFloat = 0.2
	
	var alphaValueForPresentation: CGFloat {
		switch self {
		case .ValidString:
			return 1.0
		default:
			return 0.3
		}
	}
	
	var stringValueForPresentation: String {
		switch self {
		case .ValidString(let stringValue):
			return stringValue
		case .NotRequested:
			return "(not requested)"
		case .Missing:
			return "(none)"
		case .Empty:
			return "(empty)"
		case .Multiple:
			return "(multiple)"
		case .Invalid:
			return "(invalid)"
		}
	}
}