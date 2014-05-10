//
//  ORMessage.h
//  ORMessage
//
//  Created by Robert Kramann on 09/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, ORMessageAnimationOption)
{
    ORMessageAnimationOptionNone            = 0,
    ORMessageAnimationOptionFade            = (1 << 0),
    ORMessageAnimationOptionMove            = (1 << 1),
};

@interface ORMessage : NSObject

@property(strong,nonatomic) NSArray* identifiers;

@property(strong,nonatomic) UIView* view;

@property(assign,nonatomic) BOOL hidesWhenTouched;

@property(assign,nonatomic) BOOL hidesWhenTouchedOutside;

@property(assign,nonatomic) BOOL showOnTop;

@property(assign,nonatomic) NSTimeInterval duration;

@property(assign,nonatomic) CGFloat padding;

@property(assign,nonatomic) BOOL inheritsWidthFromViewController;

@property(assign,nonatomic) ORMessageAnimationOption animationOptions;

@property(readonly,nonatomic) BOOL hidden;

@property(copy,nonatomic) void (^touchedBlock)(ORMessage* message);

@property(copy,nonatomic) void (^touchedOutsideBlock)(ORMessage* message);

@end
