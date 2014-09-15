//
//  ORMessageController.m
//  ORMessage
//
//  Created by Robert Kramann on 09/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import "ORMessageController.h"
#import "ORMessage_Private.h"
#import "UIViewController+ORMessage.h"

@interface ORMessageController () <UIGestureRecognizerDelegate>

@property(weak,nonatomic) UIViewController* viewController;

@property(strong,nonatomic) ORMessage* headerMessage;
@property(strong,nonatomic) ORMessage* footerMessage;

@property(strong,nonatomic) NSMutableArray* topMessages;
@property(strong,nonatomic) NSMutableArray* defaultMessages;

@property(strong,nonatomic) NSMutableArray* hiddenTopMessages;
@property(strong,nonatomic) NSMutableArray* hiddenDefaultMessages;

// Flags
@property(readonly,nonatomic) CGFloat offsetTop;

// Gesture recognizer
@property(strong,nonatomic) UIGestureRecognizer* windowGestureRecognizer;

// Helper
@property(readonly,nonatomic) UIView* view;

- (void)layoutMessagesExcept:(ORMessage*)message animated:(BOOL)animated;

- (CGRect)viewFrameForNewMessage:(ORMessage*)newMessage;
- (CGRect)viewFrameForMessage:(ORMessage*)message;
- (CGFloat)defaultMessagesMaxY;
- (BOOL)isTopMessage:(ORMessage*)message;
- (BOOL)isDefaultMessage:(ORMessage*)message;
- (ORMessage*)messageForMessageView:(UIView*)view;
//- (ORMessage*)messageBelowMessage:(ORMessage*)message;
//- (ORMessage*)messageAboveMessage:(ORMessage*)message;

// Timer events
- (void)messageDurationExpired:(NSTimer*)timer;

// Delegate helper
- (void)notifyDelegateMessagesLayoutChangedAnimated:(BOOL)animated;

@end

@implementation ORMessageController

- (id)initWithViewController:(UIViewController *)viewController
{
    self = [super init];
    if (self) {
        self.viewController = viewController;
        self.delegate = self.viewController;
        
        self.topMessages = [NSMutableArray new];
        self.defaultMessages = [NSMutableArray new];
        
        self.hiddenTopMessages = [NSMutableArray new];
        self.hiddenDefaultMessages = [NSMutableArray new];
        
        // Messages offset
        self.messagesOffsetTop = ({
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

- (NSArray*)messagesWithIdentifiers:(NSArray *)identifiers
{
    NSMutableArray* foundMessages = [NSMutableArray new];
    for (ORMessage* message in self.messages) {
        for (NSString* identifier in identifiers) {
            if ([message.identifiers containsObject:identifier]) {
                [foundMessages addObject:message];
            }
        }
    }
    
    return foundMessages;
}

- (void)setMessagesOffsetTop:(CGFloat)offset
{
    [self setMessagesOffsetTop:offset animated:YES];
}

- (void)setMessagesOffsetTop:(CGFloat)offset animated:(BOOL)animated
{
    _messagesOffsetTop = offset;
    
    [self layoutMessagesAnimated:animated];
}


//##################################################################
#pragma mark - Add messages
//##################################################################

- (void)addMessage:(ORMessage *)newMessage animated:(BOOL)animated
{
    if (!newMessage || !newMessage.view) {
        return;
    }
    
    if (self.headerMessage == newMessage) {
        return;
    }
    
    if ([self.topMessages indexOfObject:newMessage] != NSNotFound) {
        return;
    }
    
    if ([self.defaultMessages indexOfObject:newMessage] != NSNotFound) {
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
        
        if (newMessage.isHeaderMessage) {
            self.headerMessage = newMessage;
        } else {
            if (newMessage.showOnTop) {
                [self.topMessages insertObject:newMessage atIndex:0];
            } else {
                [self.defaultMessages addObject:newMessage];
            }
        }
        
        // Show message (animated)
        {
            // Animation start values
            CGFloat animationStartAlpha = 1.0;
            CGRect animationStartFrame = [self viewFrameForMessage:newMessage];

            if (animated && (newMessage.animationOptions & ORMessageAnimationOptionFade) == ORMessageAnimationOptionFade) {
                animationStartAlpha = 0.0;
            }
            
            if (animated && (newMessage.animationOptions & ORMessageAnimationOptionMove) == ORMessageAnimationOptionMove) {
                animationStartFrame.origin.y -= CGRectGetHeight(animationStartFrame);
            }
            
            [self.view addSubview:newMessage.view];
            [self.view bringSubviewToFront:newMessage.view];
            
            newMessage.view.alpha = animationStartAlpha;
            newMessage.view.frame = animationStartFrame;
        }
    }
    
    // Notify delegates about new message
    if (newMessage.isHeaderMessage) {
        // Header message
        if ([self.delegate respondsToSelector:@selector(messageController:didAddHeaderMessage:)]) {
            [self.delegate messageController:self didAddHeaderMessage:self.headerMessage];
        }
    }

    [self layoutMessagesAnimated:animated];
    if ([self.delegate respondsToSelector:@selector(messageController:willShowHeaderMessage:animated:)]) {
        [self.delegate messageController:self willShowHeaderMessage:self.headerMessage animated:animated];
    }
    
    [self notifyDelegateMessagesLayoutChangedAnimated:animated];
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

    if ([self isMessageHidden:message]) {
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
    
    // Remove from stack
    if (message.isHeaderMessage) {
        self.headerMessage = nil;
    } else if ([self isTopMessage:message]) {
        [self.topMessages removeObject:message];
    } else if ([self isDefaultMessage:message]) {
        [self.defaultMessages removeObject:message];
    }
    
    
    // Notify delegate about hidden message
    {
        // Header message
        if (message.isHeaderMessage) {
            if ([self.delegate respondsToSelector:@selector(messageController:willHideHeaderMessage:animated:)]) {
                [self.delegate messageController:self willHideHeaderMessage:self.headerMessage animated:animated];
            }
        }
    }
    
    [UIView animateWithDuration:(animated ? self.defaultAnimationDuration : 0.0) delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        message.view.alpha = animationEndAlpha;
        message.view.frame = animationEndFrame;
    } completion:^(BOOL finished) {
        if (message != self.headerMessage) {
            [message.view removeFromSuperview];
            
            // Notify delegate about removed message
            {
                // Header message
                if ([self.delegate respondsToSelector:@selector(messageController:didRemoveHeaderMessage:)]) {
                    [self.delegate messageController:self didRemoveHeaderMessage:self.headerMessage];
                }
            }
        }
    }];
    
    [self layoutMessagesAnimated:animated];
    
    [self notifyDelegateMessagesLayoutChangedAnimated:animated];
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
    
    [self notifyDelegateMessagesLayoutChangedAnimated:animated];
}

- (void)_showMessage:(ORMessage*)message animated:(BOOL)animated layoutMessages:(BOOL)layoutMessages
{
    if (!message || ![self isMessageHidden:message]) {
        return;
    }
    
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
    
    [self notifyDelegateMessagesLayoutChangedAnimated:animated];
}

- (void)showMessages:(NSArray *)messages animated:(BOOL)animated
{
    for (ORMessage* message in messages) {
        [self _showMessage:message animated:animated layoutMessages:NO];
    }
    
    [self layoutMessagesAnimated:animated];
    
    [self notifyDelegateMessagesLayoutChangedAnimated:animated];
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
    
    [self notifyDelegateMessagesLayoutChangedAnimated:animated];
}

- (void)_hideMessage:(ORMessage*)message animated:(BOOL)animated layoutMessages:(BOOL)layoutMessages
{
    if (!message || [self isMessageHidden:message]) {
        return;
    }
    
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
    
    [self notifyDelegateMessagesLayoutChangedAnimated:animated];
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

- (void)addHeaderMessage:(ORMessage*)headerMessage animated:(BOOL)animated
{
    if (self.headerMessage) {
        [self removeHeaderMessageAnimated:animated];
    }

    if (!headerMessage) {
        return;
    }
    
    headerMessage.isHeaderMessage = YES;
    
    [self addMessage:headerMessage animated:animated];
}

- (void)removeHeaderMessageAnimated:(BOOL)animated
{
    if (self.headerMessage) {
        [self removeMessage:self.headerMessage animated:animated];
        [self layoutMessagesAnimated:animated];
        
        [self notifyDelegateMessagesLayoutChangedAnimated:animated];
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
                message.view.alpha = 1.0;
            }
        }
    } completion:NULL];
}

- (CGFloat)offsetTop
{
    CGFloat offsetTop = self.messagesOffsetTop;
    if (self.headerMessage) {
        offsetTop += CGRectGetHeight(self.headerMessage.view.bounds);
    }
    
    return offsetTop;
}

- (CGFloat)messagesMaxY
{
    return self.defaultMessagesMaxY;
}

- (CGRect)viewFrameForMessage:(ORMessage *)message
{
    CGRect rect = CGRectZero;
    
    if (message.inheritsWidthFromViewController) {
        rect.origin.x = 0.0;
        if (message.widthLayoutReferenceView) {
            rect.size.width = CGRectGetWidth(message.widthLayoutReferenceView.bounds);
        } else {
            rect.size.width = CGRectGetWidth(self.view.bounds);
        }
    } else {
        rect.size.width = CGRectGetWidth(message.view.bounds);
        if (message.widthLayoutReferenceView) {
            rect.origin.x = (CGRectGetWidth(message.widthLayoutReferenceView.bounds) - CGRectGetWidth(rect)) / 2.0;
        } else {
            rect.origin.x = (CGRectGetWidth(self.view.bounds) - CGRectGetWidth(rect)) / 2.0;
        }
    }
    
    if ([message.delegate respondsToSelector:@selector(message:viewHeightForWidth:)]) {
        rect.size.height = [message.delegate message:message viewHeightForWidth:CGRectGetWidth(rect)];
    } else {
        rect.size.height = CGRectGetHeight(message.view.bounds);
    }
    
    if (message.isHeaderMessage) {
        rect.origin.y = self.messagesOffsetTop;
    } else if ([self isTopMessage:message]) {
        
        for (ORMessage* topMessage in self.topMessages) {
            if (topMessage != message) {
                rect.origin.y += (CGRectGetHeight(topMessage.view.bounds) + topMessage.padding);
            } else {
                break;
            }
        }
        rect.origin.y += (self.offsetTop + message.padding);
        
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
    
    return rect;
}

- (CGRect)viewFrameForNewMessage:(ORMessage *)newMessage
{
    CGRect rect = CGRectZero;
    
    if (newMessage.inheritsWidthFromViewController) {
        rect.origin.x = 0.0;
        if (newMessage.widthLayoutReferenceView) {
            rect.size.width = CGRectGetWidth(newMessage.widthLayoutReferenceView.bounds);
        } else {
            rect.size.width = CGRectGetWidth(self.view.bounds);
        }
    } else {
        rect.size.width = CGRectGetWidth(newMessage.view.bounds);
        if (newMessage.widthLayoutReferenceView) {
            rect.origin.x = (CGRectGetWidth(newMessage.widthLayoutReferenceView.bounds) - CGRectGetWidth(rect)) / 2.0;
        } else {
            rect.origin.x = (CGRectGetWidth(self.view.bounds) - CGRectGetWidth(rect)) / 2.0;
        }
    }

    rect.size.height = CGRectGetHeight(newMessage.view.bounds);

    if (newMessage.isHeaderMessage) {
        rect.origin.y = self.messagesOffsetTop;
    } else if (newMessage.showOnTop) {
        rect.origin.y = self.offsetTop + newMessage.padding;
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
    
    return self.offsetTop;
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

- (BOOL)isMessageHidden:(ORMessage*)message
{
    return ([self.hiddenDefaultMessages indexOfObject:message] != NSNotFound || [self.hiddenTopMessages indexOfObject:message] != NSNotFound);
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


//##################################################################
#pragma mark - Delegate helper
//##################################################################

- (void)notifyDelegateMessagesLayoutChangedAnimated:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(messagesLayoutChanged:animated:)]) {
        [self.delegate messagesLayoutChanged:self animated:animated];
    }
}

@end
