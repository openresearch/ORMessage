//
//  ORMessage.h
//  ORMessage
//
//  Created by Robert Kramann on 09/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ORMessage;

@protocol ORMessageViewDelegate <NSObject>
@optional
- (CGFloat)message:(ORMessage*)message viewHeightForWidth:(CGFloat)width;
@end

typedef NS_OPTIONS(NSInteger, ORMessageAnimationOption)
{
    ORMessageAnimationOptionNone            = 0,
    ORMessageAnimationOptionFade            = (1 << 0),
    ORMessageAnimationOptionMove            = (1 << 1),
};

@interface ORMessage : NSObject

@property(weak,nonatomic) id<ORMessageViewDelegate> delegate;

@property(strong,nonatomic) NSArray* identifiers;

@property(strong,nonatomic) UIView* view;

@property(assign,nonatomic) BOOL hidesWhenTouched;

@property(assign,nonatomic) BOOL hidesWhenTouchedOutside;

@property(assign,nonatomic) BOOL showOnTop;

@property(assign,nonatomic) NSTimeInterval duration;

@property(assign,nonatomic) CGFloat padding;

@property(assign,nonatomic) BOOL inheritsWidthFromViewController;

@property(assign,nonatomic) ORMessageAnimationOption animationOptions;

@property(copy,nonatomic) void (^touchedBlock)(ORMessage* message);

@property(copy,nonatomic) void (^touchedOutsideBlock)(ORMessage* message);

@property(strong,nonatomic) UIView* widthLayoutReferenceView;

- (void)removeAnimated:(BOOL)animated;
- (void)removeAfterDelay:(NSTimeInterval)delay animated:(BOOL)animated;

@end

