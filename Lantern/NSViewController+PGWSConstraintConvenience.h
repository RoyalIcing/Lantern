//
//	NSViewController+PGWSConstraintConvenience.h
//	BurntIcing
//
//	Created by Patrick Smith on 28/02/2015.
//	Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;


@interface NSViewController (PGWSConstraintConvenience)

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)constraintIdentifier;

+ (NSString *)layoutConstraintIdentifierWithBaseIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView;
- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView;

#pragma mark -

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier priority:(NSLayoutPriority)priority;

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier;

- (void)fillViewWithChildView:(NSView *)innerView;
- (void)fillWithChildViewController:(NSViewController *)childViewController;

@end
