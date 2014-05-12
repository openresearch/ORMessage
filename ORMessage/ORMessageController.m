//
//  ORMessageController.m
//  ORMessage
//
//  Created by Robert Kramann on 09/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import "ORMessageController.h"
#import "ORMessage_Private.h"


@interface ORMessageController () <UIGestureRecognizerDelegate>

@property(weak,nonatomic) UIViewController* viewController;

@property(strong,nonatomic) ORMessage* headerMessage;
@property(strong,nonatomic) ORMessage* footerMessage;

@property(strong,nonatomic) NSMutableArray* topMessages;
@property(strong,nonatomic) NSMutableArray* defaultMessages;

@property(strong,nonatomic) NSMutableArray* hiddenTopMessages;
@property(strong,nonatomic) NSMutableArray* hiddenDefaultMessages;

// Flags
@property(readonly,nonatomic) CGFloat messagesOffsetTop;

// Gesture recognizer
@property(strong,nonatomic) UIGestureRecognizer* windowGestureRecognizer;

// Helper
@property(readonly,nonatomic) UIView* view;

- (void)layoutMessagesExcept:(ORMessage*)message animated:(BOOL)animated;

- (CGRect)viewFrameForNewMessage:(ORMessage*)newMessage;
- (CGRect)viewFrameForMessage:(ORMessage*)message;
- (CGFloat)topMessagesMaxY;
- (CGFloat)defaultMessagesMaxY;
- (BOOL)isTopMessage:(ORMessage*)message;
- (BOOL)isDefaultMessage:(ORMessage*)message;
- (ORMessage*)messageForMessageView:(UIView*)view;
//- (ORMessage*)messageBelowMessage:(ORMessage*)message;
//- (ORMessage*)messageAboveMessage:(ORMessage*)message;

// Timer events
- (void)messageDurationExpired:(NSTimer*)timer;

@end

@implementation ORMessageController

- (id)initWithViewController:(UIViewController *)viewController
{
    self = [super init];
    if (self) {
        self.viewController = viewController;
        
        self.topMessages = [NSMutableArray new];
        self.defaultMessages = [NSMutableArray new];
        
        self.hiddenTopMessages = [NSMutableArray new];
        self.hiddenDefaultMessages = [NSMutableArray new];
        
        // Messages offset
        self.headerMessageOffsetTop = ({
            CGFloat offset = 0.0;
            if (self.viewController.navigationController && self.viewController.navigationController.navigationBar.translucent) {
                offset = CGRectGetMaxY(self.viewController.navigationController.navigationBar.frame);
            }
            offset;
        });
        
        // Animation duration
        self.defaultAnimationDuration = 0.25;
        
        // Window touch events
        {
            self.windowGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:nil];
            self.windowGestureRecognizer.delegate = self;
            UIWindow* applicationWindow = [UIApplication sharedApplication].windows[0];
            [applicationWindow addGestureRecognizer:self.windowGestureRecognizer];
        }
        
    }
    
    return self;
}

- (void)dealloc
{
    UIWindow* applicationWindow = [UIApplication sharedApplication].windows[0];
    [applicationWindow removeGestureRecognizer:self.windowGestureRecognizer];
}

- (NSArray*)messages
{
    NSMutableArray* messages = [NSMutableArray new];
    [messages addObjectsFromArray:self.visibleMessages];
    [messages addObjectsFromArray:self.hiddenMessages];
    
    return messages;
}

- (NSArray*)visibleMessages
{
    NSMutableArray* messages = [NSMutableArray new];
    if (self.headerMessage) {
        [messages addObject:self.headerMessage];
    }
    [messages addObjectsFromArray:self.topMessages];
    [messages addObjectsFromArray:self.defaultMessages];
    if (self.footerMessage) {
        [messages addObject:self.footerMessage];
    }
    return messages;
}

- (NSArray*)hiddenMessages
{
    NSMutableArray* messages = [NSMutableArray new];
    [messages addObjectsFromArray:self.hiddenTopMessages];
    [messages addObjectsFromArray:self.hiddenDefaultMessages];

    return messages;
}


//##################################################################
#pragma mark - Add messages
//##################################################################

- (void)addMessage:(ORMessage *)newMessage animated:(BOOL)animated
{
    if (!newMessage || !newMessage.view) {
        return;
    }
    
    newMessage.messsageController = self;
    
    // Setup new message
    {
        // Add touch events
        if (newMessage.hidesWhenTouched) {
            UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMessageTap:)];
            [newMessage.view addGestureRecognizer:tapGestureRecognizer];
        }
        
        // Timer
        {
            if (newMessage.duration > 0.0) {
                newMessage.timer = [NSTimer scheduledTimerWithTimeInterval:newMessage.duration target:self selector:@selector(messageDurationExpired:) userInfo:@{@"message": newMessage} repeats:NO];
            }
        }
        
        // Show message (animated)
        {
            // Animation end values
            CGFloat animationEndAlpha = 1.0;
            CGRect animationEndFrame = [self viewFrameForNewMessage:newMessage];
            
            // Animation start values
            CGFloat animationStartAlpha = 1.0;
            CGRect animationStartFrame = [self viewFrameForNewMessage:newMessage];

            if (animated && (newMessage.animationOptions & ORMessageAnimationOptionFade) == ORMessageAnimationOptionFade) {
                animationStartAlpha = 0.0;
            }
            
            if (animated && (newMessage.animationOptions & ORMessageAnimationOptionMove) == ORMessageAnimationOptionMove) {
                animationStartFrame.origin.y -= CGRectGetHeight(animationStartFrame);
            }
            
            [self.view addSubview:newMessage.view];

            newMessage.view.alpha = animationStartAlpha;
            newMessage.view.frame = animationStartFrame;

            if (animated) {
                [UIView animateWithDuration:self.defaultAnimationDuration animations:^{
                    newMessage.view.alpha = animationEndAlpha;
                    newMessage.view.frame = animationEndFrame;
                }];
            }
        }
        
        if (newMessage.isHeaderMessage) {
            // there's nothing to do
        } else if (newMessage.showOnTop) {
            [self.topMessages insertObject:newMessage atIndex:0];
        } else {
            [self.defaultMessages addObject:newMessage];
        }
    }
    
    [self layoutMessagesExcept:newMessage animated:YES];
}


//##################################################################
#pragma mark - Remove messages
//##################################################################

- (void)removeMessage:(ORMessage*)message animated:(BOOL)animated
{
    if (!message) {
        return;
    }
    
    // Invalidate timer
    [message.timer invalidate];

    if (message.hidden) {
        [self.hiddenTopMessages removeObject:message];
        [self.hiddenDefaultMessages removeObject:message];
        return;
    }

    // Animation end values
    CGFloat animationEndAlpha = 1.0;
    CGRect animationEndFrame = message.view.frame;
    
    if (animated && (message.animationOptions & ORMessageAnimationOptionFade) == ORMessageAnimationOptionFade) {
        animationEndAlpha = 0.0;
    }
    
    if (animated && (message.animationOptions & ORMessageAnimationOptionMove) == ORMessageAnimationOptionMove) {
        animationEndFrame.origin.y -= CGRectGetHeight(animationEndFrame);
    }
    
    [UIView animateWithDuration:(animated ? self.defaultAnimationDuration : 0.0) delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        message.view.alpha = animationEndAlpha;
        message.view.frame = animationEndFrame;
    } completion:^(BOOL finished) {
        [message.view removeFromSuperview];
    }];
    
    // Remove from stack
    if (message.isHeaderMessage) {
        self.headerMessage = nil;
    } else if ([self isTopMessage:message]) {
        [self.topMessages removeObject:message];
    } else if ([self isDefaultMessage:message]) {
        [self.defaultMessages removeObject:message];
    }
    
    [self layoutMessagesAnimated:animated];
}

- (void)removeMessages:(NSArray *)messages animated:(BOOL)animated
{
    for (ORMessage* message in messages) {
        [self removeMessage:message animated:animated];
    }
}

- (void)removeMessagesWithIdentifiers:(NSArray*)identifiers animated:(BOOL)animated
{
    NSMutableArray* messagesToRemove = [NSMutableArray new];
    for (ORMessage* message in self.messages) {
        for (NSString* identifier in identifiers) {
            if ([message.identifiers containsObject:identifier]) {
                [messagesToRemove addObject:message];
            }
        }
    }
    
    [self removeMessages:messagesToRemove animated:animated];
}

- (void)removeAllMessagesAnimated:(BOOL)animated
{
    for (ORMessage* message in self.messages) {
        [self removeMessage:message animated:animated];
    }
}


//##################################################################
#pragma mark - Show / hide messages
//##################################################################

- (void)showMessage:(ORMessage*)message animated:(BOOL)animated
{
    [self _showMessage:message animated:animated layoutMessages:YES];
}

- (void)_showMessage:(ORMessage*)message animated:(BOOL)animated layoutMessages:(BOOL)layoutMessages
{
    if (!message || !message.hidden) {
        return;
    }
    
    message.hidden = NO;
    
    if (message.showOnTop) {
        [self.topMessages insertObject:message atIndex:0];
    } else {
        [self.defaultMessages addObject:message];
    }
    
    [self.hiddenTopMessages removeObject:message];
    [self.hiddenDefaultMessages removeObject:message];
    
    message.view.alpha = 0.0;
    message.view.frame = [self viewFrameForMessage:message];
    [self.view addSubview:message.view];
    
    [UIView animateWithDuration:(animated ? self.defaultAnimationDuration : 0.0) delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        message.view.alpha = 1.0;
    } completion:NULL];
    
    if (layoutMessages) {
        [self layoutMessagesAnimated:animated];
    }
}

- (void)showAllMessagesAnimated:(BOOL)animated
{
    for (ORMessage* message in self.hiddenMessages) {
        [self _showMessage:message animated:animated layoutMessages:NO];
    }
    
    [self layoutMessagesAnimated:animated];
}

- (void)showMessages:(NSArray *)messages animated:(BOOL)animated
{
    for (ORMessage* message in messages) {
        [self _showMessage:message animated:animated layoutMessages:NO];
    }
    
    [self layoutMessagesAnimated:animated];
}

- (void)showMessagesWithIdentifiers:(NSArray*)identifiers animated:(BOOL)animated
{
    NSMutableArray* messagesToShow = [NSMutableArray new];
    for (ORMessage* message in self.hiddenMessages) {
        for (NSString* identifier in identifiers) {
            if ([message.identifiers containsObject:identifier]) {
                [messagesToShow addObject:message];
            }
        }
    }
    
    [self showMessages:messagesToShow animated:animated];
}

- (void)hideMessage:(ORMessage*)message animated:(BOOL)animated
{
    [self _hideMessage:message animated:animated layoutMessages:YES];
}

- (void)_hideMessage:(ORMessage*)message animated:(BOOL)animated layoutMessages:(BOOL)layoutMessages
{
    if (!message || message.hidden) {
        return;
    }
    
    message.hidden = YES;
    
    if (message.showOnTop) {
        [self.hiddenTopMessages insertObject:message atIndex:0];
    } else {
        [self.hiddenDefaultMessages addObject:message];
    }
    
    [self.topMessages removeObject:message];
    [self.defaultMessages removeObject:message];
    
    [UIView animateWithDuration:(animated ? self.defaultAnimationDuration : 0.0) delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        message.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [message.view removeFromSuperview];
        }
    }];
    
    if (layoutMessages) {
        [self layoutMessagesAnimated:animated];
    }
}

- (void)hideMessages:(NSArray *)messages animated:(BOOL)animated
{
    for (ORMessage* message in messages) {
        [self _hideMessage:message animated:animated layoutMessages:NO];
    }
    
    [self layoutMessagesAnimated:animated];
}

- (void)hideMessagesWithIdentifiers:(NSArray*)identifiers animated:(BOOL)animated
{
    NSMutableArray* messagesToHide = [NSMutableArray new];
    for (ORMessage* message in self.visibleMessages) {
        for (NSString* identifier in identifiers) {
            if ([message.identifiers containsObject:identifier]) {
                [messagesToHide addObject:message];
            }
        }
    }
    
    [self hideMessages:messagesToHide animated:animated];
}

- (void)hideAllMessagesAnimated:(BOOL)animated
{
    [self hideMessages:self.visibleMessages animated:animated];
}


//##################################################################
#pragma mark - Header message
//##################################################################

- (void)setHeaderMessageOffsetTop:(CGFloat)headerMessageOffsetTop
{
    [self setHeaderMessageOffsetTop:headerMessageOffsetTop animated:YES];
}

- (void)setHeaderMessageOffsetTop:(CGFloat)headerMessageOffsetTop animated:(BOOL)animated
{
    _headerMessageOffsetTop = headerMessageOffsetTop;
    
    [self layoutMessagesAnimated:animated];
}

- (void)addHeaderMessage:(ORMessage*)headerMessage animated:(BOOL)animated
{
    if (self.headerMessage) {
        [self removeHeaderMessageAnimated:animated];
    }

    if (!headerMessage) {
        return;
    }
    
    headerMessage.isHeaderMessage = YES;
    
    self.headerMessage = headerMessage;
    [self addMessage:headerMessage animated:animated];
}

- (void)removeHeaderMessageAnimated:(BOOL)animated
{
    if (self.headerMessage) {
        [self removeMessage:self.headerMessage animated:animated];
        [self layoutMessagesAnimated:animated];
    }
}

//##################################################################
#pragma mark - Helper
//##################################################################

- (UIView*)view
{
    return self.viewController.view;
}

- (void)layoutMessagesAnimated:(BOOL)animated
{
    [self layoutMessagesExcept:nil animated:animated];
}

- (void)layoutMessagesExcept:(ORMessage*)exceptedMessage animated:(BOOL)animated
{
    [UIView animateWithDuration:(animated ? self.defaultAnimationDuration : 0.0) delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        for (ORMessage* message in self.visibleMessages) {
            if (message != exceptedMessage) {
                message.view.frame = [self viewFrameForMessage:message];
            }
        }
    } completion:NULL];
}

- (CGFloat)messagesOffsetTop
{
    CGFloat offsetTop = self.headerMessageOffsetTop;
    if (self.headerMessage) {
        offsetTop += CGRectGetHeight(self.headerMessage.view.bounds);
    }
    
    return offsetTop;
}

- (CGRect)viewFrameForMessage:(ORMessage *)message
{
    CGRect rect = CGRectZero;
    
    if (message.isHeaderMessage) {
        rect.origin.y = self.headerMessageOffsetTop;
    } else if ([self isTopMessage:message]) {
        
        for (ORMessage* topMessage in self.topMessages) {
            if (topMessage != message) {
                rect.origin.y += (CGRectGetHeight(topMessage.view.bounds) + topMessage.padding);
            } else {
                break;
            }
        }
        rect.origin.y += (self.messagesOffsetTop + message.padding);
        
    } else if ([self isDefaultMessage:message]) {
        
        rect.origin.y = [self topMessagesMaxY];
        
        for (ORMessage* defaultMessage in self.defaultMessages) {
            if (defaultMessage != message) {
                rect.origin.y += (CGRectGetHeight(defaultMessage.view.bounds) + defaultMessage.padding);
            } else {
                break;
            }
        }

        rect.origin.y += message.padding;
    }
    
    rect.size.height = CGRectGetHeight(message.view.bounds);

    if (message.inheritsWidthFromViewController) {
        rect.origin.x = 0.0;
        rect.size.width = CGRectGetWidth(self.view.bounds);
    } else {
        rect.size.width = CGRectGetWidth(message.view.bounds);
        rect.origin.x = (CGRectGetWidth(self.view.bounds) - CGRectGetWidth(rect)) / 2.0;
    }
    
    return rect;
}

- (CGRect)viewFrameForNewMessage:(ORMessage *)newMessage
{
    CGRect rect = CGRectZero;
    if (newMessage.inheritsWidthFromViewController) {
        rect.origin.x = 0.0;
        rect.size.width = CGRectGetWidth(self.view.bounds);
    } else {
        rect.size.width = CGRectGetWidth(newMessage.view.bounds);
        rect.origin.x = (CGRectGetWidth(self.view.frame) - CGRectGetWidth(rect)) / 2.0;
    }

    rect.size.height = CGRectGetHeight(newMessage.view.bounds);

    if (newMessage.isHeaderMessage) {
        rect.origin.y = self.headerMessageOffsetTop;
    } else if (newMessage.showOnTop) {
        rect.origin.y = self.messagesOffsetTop + newMessage.padding;
    } else {
        rect.origin.y = [self defaultMessagesMaxY] + newMessage.padding;
    }
    
    return rect;
}

- (CGFloat)topMessagesMaxY
{
    ORMessage* oldestTopMessage = [self.topMessages lastObject];
    if (oldestTopMessage) {
        return CGRectGetMaxY(oldestTopMessage.view.frame);
    }
    
    return self.messagesOffsetTop;
}

- (CGFloat)defaultMessagesMaxY
{
    CGFloat topMessagesMaxY = [self topMessagesMaxY];
    
    ORMessage* oldestDefaultMessage = [self.defaultMessages lastObject];
    if (oldestDefaultMessage) {
        return CGRectGetMaxY(oldestDefaultMessage.view.frame);
    }
    
    return topMessagesMaxY;
}

- (BOOL)isTopMessage:(ORMessage *)message
{
    return ([self.topMessages indexOfObject:message] != NSNotFound || [self.hiddenTopMessages indexOfObject:message] != NSNotFound);
}

- (BOOL)isDefaultMessage:(ORMessage *)message
{
    return ([self.defaultMessages indexOfObject:message] != NSNotFound || [self.hiddenDefaultMessages indexOfObject:message] != NSNotFound);
}

- (ORMessage*)messageForMessageView:(UIView*)view
{
    for (ORMessage* message in self.messages) {
        if (message.view == view) {
            return message;
        }
    }
    
    return nil;
}

//##################################################################
#pragma mark - UIGestureRecognizerDelegate / Events
//##################################################################

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    NSMutableArray* messagesToRemove = [NSMutableArray new];
    for (ORMessage* message in self.visibleMessages) {
        CGPoint touchPoint = [touch locationInView:message.view];
        if (!CGRectContainsPoint(message.view.bounds, touchPoint)) {
            
            // Call block
            if (message.touchedOutsideBlock) {
                message.touchedOutsideBlock(message);
            }
            
            // Remove message
            if (message.hidesWhenTouchedOutside) {
                [messagesToRemove addObject:message];
            }
        } else {
            // Call block
            if (message.touchedBlock) {
                message.touchedBlock(message);
            }
        }
    }
    
    for (ORMessage* message in messagesToRemove) {
        [self removeMessage:message animated:YES];
    }
    
    return NO;
}

- (void)handleMessageTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        ORMessage* message = [self messageForMessageView:sender.view];
        if (message) {
            // Remove message
            if (message.hidesWhenTouched) {
                [self removeMessage:message animated:YES];
            }
        }
    }
}


//##################################################################
#pragma mark - Timer
//##################################################################

- (void)messageDurationExpired:(NSTimer*)timer
{
    ORMessage* message = timer.userInfo[@"message"];
    if (message) {
        // Remove message
        [self removeMessage:message animated:YES];
    }
}


@end
