//
//  NSSegmentedControl+PGWSConvenience.m
//  Hoverlytics
//
//  Created by Patrick Smith on 27/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "NSSegmentedControl+PGWSConvenience.h"


@implementation NSSegmentedControl (PGWSConvenience)

- (NSInteger)tagOfSelectedSegment
{
	NSSegmentedCell *cell = (self.cell);
	NSInteger selectedSegment = (cell.selectedSegment);
	if (selectedSegment == -1) {
		return -1;
	}
	else {
		return [cell tagForSegment:selectedSegment];
	}
}

@end
