//
//  UIBarButtonItem+Badge.m
//  RoboForm
//
//  Created by Alexey Zarva on 27.04.18.
//  Copyright (c) 2018 Siber Systems, Inc. All rights reserved.
//
#import <objc/runtime.h>
#import "UIBarButtonItem+Badge.h"

NSString const *UIBarButtonItem_badgeKey = @"UIBarButtonItem_badgeKey";
NSString const *UIBarButtonItem_badgeContainerKey = @"UIBarButtonItem_badgeContainerKey";
NSString const *UIBarButtonItem_badgeSizeConstraintsKey = @"UIBarButtonItem_badgeSizeConstraintsKey";
NSString const *UIBarButtonItem_badgeOffsetConstraintsKey = @"UIBarButtonItem_badgeOffsetConstraintsKey";
NSString const *UIBarButtonItem_badgeBGColorKey = @"UIBarButtonItem_badgeBGColorKey";
NSString const *UIBarButtonItem_badgeTextColorKey = @"UIBarButtonItem_badgeTextColorKey";
NSString const *UIBarButtonItem_badgeFontKey = @"UIBarButtonItem_badgeFontKey";
NSString const *UIBarButtonItem_badgePaddingKey = @"UIBarButtonItem_badgePaddingKey";
NSString const *UIBarButtonItem_badgeMinSizeKey = @"UIBarButtonItem_badgeMinSizeKey";
NSString const *UIBarButtonItem_badgeOriginXKey = @"UIBarButtonItem_badgeOriginXKey";
NSString const *UIBarButtonItem_badgeOriginYKey = @"UIBarButtonItem_badgeOriginYKey";
NSString const *UIBarButtonItem_shouldHideBadgeAtZeroKey = @"UIBarButtonItem_shouldHideBadgeAtZeroKey";
NSString const *UIBarButtonItem_shouldAnimateBadgeKey = @"UIBarButtonItem_shouldAnimateBadgeKey";
NSString const *UIBarButtonItem_badgeValueKey = @"UIBarButtonItem_badgeValueKey";


@implementation UIBarButtonItem (Badge)

@dynamic badgeValue, badgeBGColor, badgeTextColor, badgeFont;
@dynamic badgePadding, badgeMinSize, badgeOffsetX, badgeOffsetY;
@dynamic shouldHideBadgeAtZero, shouldAnimateBadge;


- (void)badgeInit
{
    // Default design initialization
    self.badgeBGColor   = [UIColor redColor];
    self.badgeTextColor = [UIColor whiteColor];
    self.badgeFont      = [UIFont systemFontOfSize:12.0];
    self.badgePadding   = 6;
    self.badgeMinSize   = 8;
	self.badgeOffsetX   = 0;
    self.badgeOffsetY   = 0;
    self.shouldHideBadgeAtZero = YES;
    self.shouldAnimateBadge = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)addBadgeToSuperView {
	UIView *labelContainer = [self labelContainer];
	if (labelContainer.superview != nil) {
		return;
	}
	UIView *superview = nil;
	if (self.customView) {
		superview = self.customView;
		superview.clipsToBounds = NO;
	} else if ([self respondsToSelector:@selector(view)] && [(id)self view]) {
		superview = [(id)self view];
	}
	[superview addSubview:labelContainer];
	
	NSLayoutConstraint *offsetYConstraint = [NSLayoutConstraint constraintWithItem:labelContainer
																		 attribute:NSLayoutAttributeBottom
																		 relatedBy:NSLayoutRelationEqual
																			toItem:superview
																		 attribute:NSLayoutAttributeCenterY
																		multiplier:1.0
																		  constant:-self.badgeOffsetY];
	NSLayoutConstraint *offsetXConstraint = [NSLayoutConstraint constraintWithItem:labelContainer
																		 attribute:NSLayoutAttributeLeft
																		 relatedBy:NSLayoutRelationEqual
																			toItem:superview
																		 attribute:NSLayoutAttributeCenterX
																		multiplier:1.0
																		  constant:self.badgeOffsetX];
	[superview removeConstraints:[self badgeOffsetConstraints]];
	[self setBadgeOffsetConstraints:@[offsetXConstraint, offsetYConstraint]];
	[superview addConstraints:[self badgeOffsetConstraints]];
	[self refreshBadge];
}

- (void)didRotate:(NSNotification *)notification {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self refreshBadge];
		UIView *labelContainer = [self labelContainer];
		[labelContainer.superview bringSubviewToFront:labelContainer];
	});
}

#pragma mark - Utility methods

// Handle badge display when its properties have been changed (color, font, ...)
- (void)refreshBadge {
    // Change new attributes
    self.badge.textColor        = self.badgeTextColor;
	self.badge.backgroundColor  = [UIColor clearColor];
    self.badge.font             = self.badgeFont;
	
	[self labelContainer].backgroundColor = self.badgeBGColor;
    
    if (!self.badgeValue || [self.badgeValue isEqualToString:@""] || ([self.badgeValue isEqualToString:@"0"] && self.shouldHideBadgeAtZero)) {
        [self labelContainer].hidden = YES;
    } else {
        [self labelContainer].hidden = NO;
        [self updateBadgeValueAnimated:YES];
    }
}

- (CGSize) badgeExpectedSize {
    // When the value changes the badge could need to get bigger
    // Calculate expected size to fit new value
    // Use an intermediate label to get expected size thanks to sizeToFit
    // We don't call sizeToFit on the true label to avoid bad display
	
	UILabel *duplicateLabel = [[UILabel alloc] initWithFrame:self.badge.frame];
	duplicateLabel.text = self.badge.text;
	duplicateLabel.font = self.badge.font;
	
    [duplicateLabel sizeToFit];
    
    CGSize expectedLabelSize = duplicateLabel.frame.size;
    return expectedLabelSize;
}

- (void)updateBadgeFrame {
    CGSize expectedLabelSize = [self badgeExpectedSize];
    
    // Make sure that for small value, the badge will be big enough
    CGFloat minHeight = expectedLabelSize.height;
    
    // Using a const we make sure the badge respect the minimum size
    minHeight = (minHeight < self.badgeMinSize) ? self.badgeMinSize : expectedLabelSize.height;
    CGFloat minWidth = expectedLabelSize.width;
    CGFloat padding = self.badgePadding;
    
    // Using const we make sure the badge doesn't get too small
    minWidth = (minWidth < minHeight) ? minHeight : expectedLabelSize.width;
	
	CGRect badgeFrame = self.badge.frame;
	badgeFrame.size = CGSizeMake(minWidth + padding, minHeight + padding);
	
	UIView *labelContainer = [self labelContainer];
	if (!CGSizeEqualToSize(labelContainer.frame.size, badgeFrame.size)) {
		NSArray *sizeConstraints = [self badgeSizeConstraints];
		NSLayoutConstraint *widthConstraint = sizeConstraints[0];
		NSLayoutConstraint *heightConstraint = sizeConstraints[1];
		widthConstraint.constant = badgeFrame.size.width;
		heightConstraint.constant = badgeFrame.size.height;
	}
	labelContainer.layer.masksToBounds = YES;
    labelContainer.layer.cornerRadius = (minHeight + padding) / 2;
	
	NSArray *offsetConstraints = [self badgeOffsetConstraints];
	NSLayoutConstraint *offsetXConstraint = offsetConstraints[0];
	NSLayoutConstraint *offsetYConstraint = offsetConstraints[1];
	offsetXConstraint.constant = self.badgeOffsetX;
	offsetYConstraint.constant = self.badgeOffsetY;
	
	[self.badge.superview layoutIfNeeded];
}

// Handle the badge changing value
- (void)updateBadgeValueAnimated:(BOOL)animated {
    // Bounce animation on badge if value changed and if animation authorized
    if (animated && self.shouldAnimateBadge && ![self.badge.text isEqualToString:self.badgeValue]) {
        CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        [animation setFromValue:[NSNumber numberWithFloat:1.5]];
        [animation setToValue:[NSNumber numberWithFloat:1]];
        [animation setDuration:0.2];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.4f :1.3f :1.f :1.f]];
        [self.badge.layer addAnimation:animation forKey:@"bounceAnimation"];
    }
    
    // Set the new value
    self.badge.text = self.badgeValue;
    
    // Animate the size modification if needed
    if (animated && self.shouldAnimateBadge) {
        [UIView animateWithDuration:0.2 animations:^{
            [self updateBadgeFrame];
        }];
    } else {
        [self updateBadgeFrame];
    }
}

- (void)removeBadge {
    // Animate badge removal
    [UIView animateWithDuration:0.2 animations:^{
        self.badge.transform = CGAffineTransformMakeScale(0, 0);
    } completion:^(BOOL finished) {
		[[self labelContainer] removeFromSuperview];
		[self setLabelContainer:nil];
        [self.badge removeFromSuperview];
        self.badge = nil;
    }];
}

- (void)updateBadge {
	UIView *labelContainer = [self labelContainer];
	if (labelContainer.window == nil) {
		[labelContainer removeFromSuperview];
	}
	[self addBadgeToSuperView];
}

#pragma mark - getters/setters
- (UILabel*)badge {
	UILabel* label = objc_getAssociatedObject(self, &UIBarButtonItem_badgeKey);
	if (label == nil) {
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.textAlignment = NSTextAlignmentCenter;
		[label sizeToFit];
		label.translatesAutoresizingMaskIntoConstraints = NO;
		[self setBadge:label];
		[self badgeInit];
		
		UIView *labelContainer = [[UIView alloc] initWithFrame:CGRectZero];
		labelContainer.translatesAutoresizingMaskIntoConstraints = NO;
		[labelContainer addSubview:label];
		[self setLabelContainer:labelContainer];

		[labelContainer addConstraint:[NSLayoutConstraint constraintWithItem:label
																   attribute:NSLayoutAttributeCenterX
																   relatedBy:NSLayoutRelationEqual
																	  toItem:labelContainer
																   attribute:NSLayoutAttributeCenterX
																  multiplier:1.0
																	constant:0]];
		[labelContainer addConstraint:[NSLayoutConstraint constraintWithItem:label
																   attribute:NSLayoutAttributeCenterY
																   relatedBy:NSLayoutRelationEqual
																	  toItem:labelContainer
																   attribute:NSLayoutAttributeCenterY
																  multiplier:1.0
																	constant:0]];
		NSLayoutConstraint *constraintWidth = [NSLayoutConstraint constraintWithItem:labelContainer
																		   attribute:NSLayoutAttributeWidth
																		   relatedBy:NSLayoutRelationEqual
																			  toItem:nil
																		   attribute:NSLayoutAttributeNotAnAttribute
																		  multiplier:1.0
																		  	constant:0];
		NSLayoutConstraint *constraintHeight = [NSLayoutConstraint constraintWithItem:labelContainer
																			attribute:NSLayoutAttributeHeight
																			relatedBy:NSLayoutRelationEqual
																			   toItem:nil
																			attribute:NSLayoutAttributeNotAnAttribute
																		   multiplier:1.0
																			 constant:0];
		[self setBadgeSizeConstraints:@[constraintWidth, constraintHeight]];
		[labelContainer addConstraints:[self badgeSizeConstraints]];
	}
	return label;
}

- (void)setBadge:(UILabel *)badgeLabel {
    objc_setAssociatedObject(self, &UIBarButtonItem_badgeKey, badgeLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)labelContainer {
	UIView *labelContainer = objc_getAssociatedObject(self, &UIBarButtonItem_badgeContainerKey);
	return labelContainer;
}

- (void)setLabelContainer:(UIView *)labelContainer {
	objc_setAssociatedObject(self, &UIBarButtonItem_badgeContainerKey, labelContainer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)badgeSizeConstraints {
	NSArray *badgeSizeConstraints = objc_getAssociatedObject(self, &UIBarButtonItem_badgeSizeConstraintsKey);
	return badgeSizeConstraints;
}

- (void)setBadgeSizeConstraints:(NSArray *)badgeSizeConstraints {
	objc_setAssociatedObject(self, &UIBarButtonItem_badgeSizeConstraintsKey, badgeSizeConstraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)badgeOffsetConstraints {
	NSArray *badgeOffsetConstraints = objc_getAssociatedObject(self, &UIBarButtonItem_badgeOffsetConstraintsKey);
	return badgeOffsetConstraints;
}

- (void)setBadgeOffsetConstraints:(NSArray *)badgeOffsetConstraints {
	objc_setAssociatedObject(self, &UIBarButtonItem_badgeOffsetConstraintsKey, badgeOffsetConstraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Badge value to be display
- (NSString *)badgeValue {
    return objc_getAssociatedObject(self, &UIBarButtonItem_badgeValueKey);
}

- (void)setBadgeValue:(NSString *)badgeValue {
    objc_setAssociatedObject(self, &UIBarButtonItem_badgeValueKey, badgeValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // When changing the badge value check if we need to remove the badge
    [self updateBadgeValueAnimated:YES];
    [self refreshBadge];
}

// Badge background color
- (UIColor *)badgeBGColor {
    return objc_getAssociatedObject(self, &UIBarButtonItem_badgeBGColorKey);
}

- (void)setBadgeBGColor:(UIColor *)badgeBGColor {
    objc_setAssociatedObject(self, &UIBarButtonItem_badgeBGColorKey, badgeBGColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self refreshBadge];
    }
}

// Badge text color
- (UIColor *)badgeTextColor {
    return objc_getAssociatedObject(self, &UIBarButtonItem_badgeTextColorKey);
}

- (void)setBadgeTextColor:(UIColor *)badgeTextColor {
    objc_setAssociatedObject(self, &UIBarButtonItem_badgeTextColorKey, badgeTextColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self refreshBadge];
    }
}

// Badge font
- (UIFont *)badgeFont {
    return objc_getAssociatedObject(self, &UIBarButtonItem_badgeFontKey);
}

- (void)setBadgeFont:(UIFont *)badgeFont {
    objc_setAssociatedObject(self, &UIBarButtonItem_badgeFontKey, badgeFont, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self refreshBadge];
    }
}

// Padding value for the badge
- (CGFloat) badgePadding {
    NSNumber *number = objc_getAssociatedObject(self, &UIBarButtonItem_badgePaddingKey);
    return number.floatValue;
}

- (void)setBadgePadding:(CGFloat)badgePadding {
    NSNumber *number = [NSNumber numberWithDouble:badgePadding];
    objc_setAssociatedObject(self, &UIBarButtonItem_badgePaddingKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self updateBadgeFrame];
    }
}

// Minimum size badge to small
- (CGFloat) badgeMinSize {
    NSNumber *number = objc_getAssociatedObject(self, &UIBarButtonItem_badgeMinSizeKey);
    return number.floatValue;
}

- (void)setBadgeMinSize:(CGFloat)badgeMinSize {
    NSNumber *number = [NSNumber numberWithDouble:badgeMinSize];
    objc_setAssociatedObject(self, &UIBarButtonItem_badgeMinSizeKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self updateBadgeFrame];
    }
}

// Values for offseting the badge over the BarButtonItem you picked
- (CGFloat)badgeOffsetX {
    NSNumber *number = objc_getAssociatedObject(self, &UIBarButtonItem_badgeOriginXKey);
    return number.floatValue;
}

- (void)setBadgeOffsetX:(CGFloat)badgeOffsetX {
    NSNumber *number = [NSNumber numberWithDouble:badgeOffsetX];
    objc_setAssociatedObject(self, &UIBarButtonItem_badgeOriginXKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self updateBadgeFrame];
    }
}

- (CGFloat)badgeOffsetY {
    NSNumber *number = objc_getAssociatedObject(self, &UIBarButtonItem_badgeOriginYKey);
    return number.floatValue;
}

- (void)setBadgeOffsetY:(CGFloat)badgeOffsetY {
    NSNumber *number = [NSNumber numberWithDouble:badgeOffsetY];
    objc_setAssociatedObject(self, &UIBarButtonItem_badgeOriginYKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self updateBadgeFrame];
    }
}

// In case of numbers, remove the badge when reaching zero
- (BOOL)shouldHideBadgeAtZero {
    NSNumber *number = objc_getAssociatedObject(self, &UIBarButtonItem_shouldHideBadgeAtZeroKey);
    return number.boolValue;
}

- (void)setShouldHideBadgeAtZero:(BOOL)shouldHideBadgeAtZero {
    NSNumber *number = [NSNumber numberWithBool:shouldHideBadgeAtZero];
    objc_setAssociatedObject(self, &UIBarButtonItem_shouldHideBadgeAtZeroKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self refreshBadge];
    }
}

// Badge has a bounce animation when value changes
- (BOOL)shouldAnimateBadge {
    NSNumber *number = objc_getAssociatedObject(self, &UIBarButtonItem_shouldAnimateBadgeKey);
    return number.boolValue;
}

- (void)setShouldAnimateBadge:(BOOL)shouldAnimateBadge {
    NSNumber *number = [NSNumber numberWithBool:shouldAnimateBadge];
    objc_setAssociatedObject(self, &UIBarButtonItem_shouldAnimateBadgeKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.badge) {
        [self refreshBadge];
    }
}

@end
