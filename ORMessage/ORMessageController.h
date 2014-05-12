//
//  ORMessageController.h
//  ORMessage
//
//  Created by Robert Kramann on 09/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ORMessage.h"

@interface ORMessageController : NSObject

@property(readonly,nonatomic) NSArray* messages;
@property(readonly,nonatomic) NSArray* visibleMessages;
@property(readonly,nonatomic) NSArray* hiddenMessages;

@property(assign,nonatomic) CGFloat messagesOffsetTop;
- (void)setMessagesOffsetTop:(CGFloat)offset animated:(BOOL)animated;

@property(readonly,weak,nonatomic) UIViewController* viewController;

@property(assign,nonatomic) CGFloat defaultAnimationDuration;

- (void)addMessage:(ORMessage *)message animated:(BOOL)animated;

- (void)removeMessage:(ORMessage *)message animated:(BOOL)animated;
- (void)removeMessages:(NSArray*)messages animated:(BOOL)animated;
- (void)removeMessagesWithIdentifiers:(NSArray*)identifiers animated:(BOOL)animated;
- (void)removeAllMessagesAnimated:(BOOL)animated;

- (void)showMessage:(ORMessage*)message animated:(BOOL)animated;
- (void)showMessages:(NSArray*)messages animated:(BOOL)animated;
- (void)showMessagesWithIdentifiers:(NSArray*)identifiers animated:(BOOL)animated;
- (void)showAllMessagesAnimated:(BOOL)animated;

- (void)hideMessage:(ORMessage*)message animated:(BOOL)animated;
- (void)hideMessages:(NSArray*)messages animated:(BOOL)animated;
- (void)hideMessagesWithIdentifiers:(NSArray*)identifiers animated:(BOOL)animated;
- (void)hideAllMessagesAnimated:(BOOL)animated;

//##################################################################
#pragma mark - Header message
//##################################################################

@property(readonly,nonatomic) ORMessage* headerMessage;
- (void)addHeaderMessage:(ORMessage*)headerMessage animated:(BOOL)animated;
- (void)removeHeaderMessageAnimated:(BOOL)animated;


//##################################################################
#pragma mark - Layout messages
//##################################################################

- (void)layoutMessagesAnimated:(BOOL)animated;


//##################################################################
#pragma mark - Init
//##################################################################

- (id)initWithViewController:(UIViewController*)viewController;

@end
