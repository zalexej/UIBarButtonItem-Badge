//
//  UIBarButtonItem+Badge.h
//  RoboForm
//
//  Created by Alexey Zarva on 27.04.18.
//  Copyright (c) 2018 Siber Systems, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Badge)

@property (strong, atomic) UILabel *badge;

// Badge value to be display
@property (nonatomic) NSString *badgeValue;
// Badge background color
@property (nonatomic) UIColor *badgeBGColor;
// Badge text color
@property (nonatomic) UIColor *badgeTextColor;
// Badge font
@property (nonatomic) UIFont *badgeFont;
// Padding value for the badge
@property (nonatomic) CGFloat badgePadding;
// Minimum size badge to small
@property (nonatomic) CGFloat badgeMinSize;

// Values for offseting the badge
@property (nonatomic) CGFloat badgeOffsetX;
@property (nonatomic) CGFloat badgeOffsetY;

// In case of numbers, remove the badge when reaching zero
@property BOOL shouldHideBadgeAtZero;
// Badge has a bounce animation when value changes
@property BOOL shouldAnimateBadge;

- (void)updateBadge;

@end
