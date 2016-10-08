//
//	NSViewController+PGWSConstraintConvenience.m
//	BurntIcing
//
//	Created by Patrick Smith on 28/02/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "NSViewController+PGWSConstraintConvenience.h"


@implementation NSViewController (PGWSConstraintConvenience)

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)constraintIdentifier
{
	NSArray *leadingConstraintInArray = [(self.view.constraints) filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", constraintIdentifier]];
	
	if (leadingConstraintInArray.count == 0) {
		return nil;
	}
	else {
		return leadingConstraintInArray[0];
	}
}

+ (NSString *)layoutConstraintIdentifierWithBaseIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView
{
	return [NSString stringWithFormat:@"%@--%@", (innerView.identifier), baseIdentifier];
}

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView
{
	if (!innerView) {
		return nil;
	}
	
	NSString *constraintIdentifier = [(self.class) layoutConstraintIdentifierWithBaseIdentifier:baseIdentifier forChildView:innerView];
	return [self layoutConstraintWithIdentifier:constraintIdentifier];
}

#pragma mark -

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier priority:(NSLayoutPriority)priority
{
	NSParameterAssert(innerView != nil);
	NSParameterAssert(identifier != nil);
	
	NSView *holderView = (self.view);
	
	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:innerView attribute:attribute relatedBy:NSLayoutRelationEqual toItem:holderView attribute:attribute multiplier:1.0 constant:0.0];
	
	(constraint.identifier) = [(self.class) layoutConstraintIdentifierWithBaseIdentifier:identifier forChildView:innerView];
	(constraint.priority) = priority;
	
	[holderView addConstraint:constraint];
	
	return constraint;
}

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier
{
	return [self addLayoutConstraintToMatchAttribute:attribute withChildView:innerView identifier:identifier priority:NSLayoutPriorityRequired];
}

- (void)fillViewWithChildView:(NSView *)innerView
{
	NSParameterAssert(innerView != nil);
	
	if (!(innerView.identifier)) {
		NSUUID *UUID = [NSUUID UUID];
		(innerView.identifier) = [NSString stringWithFormat:@"(%@)", (UUID.UUIDString)];
	}
	
	[(self.view) addSubview:innerView];
	
	// Interface Builder's default is to have this on for new view controllers in 10.9 for some reason.
	// I have disabled it where I remember to in the xib file, but no harm in just setting it off here too.
	(innerView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	// By setting width and height constraints, we can move the view around whilst keeping it the same size.
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeWidth withChildView:innerView identifier:@"width"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeHeight withChildView:innerView identifier:@"height"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:innerView identifier:@"leading"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeTop withChildView:innerView identifier:@"top"];
}

- (void)fillWithChildViewController:(NSViewController *)childViewController
{
	NSParameterAssert(childViewController != nil);
	
	[self addChildViewController:childViewController];
	[self fillViewWithChildView:(childViewController.view)];
}

@end
