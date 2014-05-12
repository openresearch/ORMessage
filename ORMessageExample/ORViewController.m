//
//  ORViewController.m
//  ORMessageExample
//
//  Created by Robert Kramann on 10/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import "ORViewController.h"

#import "UIViewController+ORMessage.h"

#import "ORMessageExampleView.h"

@interface ORViewController ()

@property(strong,nonatomic) UIToolbar* toolbar;

@end

@implementation ORViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = @"Messages";
    
    NSMutableArray* leftButtonItems = [NSMutableArray new];
    [leftButtonItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMessage)]];
    [leftButtonItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(addMessageOnTop)]];
    [leftButtonItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(addMessageWithDuration)]];

    self.navigationItem.leftBarButtonItems = leftButtonItems;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeAllMessages)];
    
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    NSMutableArray* toolbarItems = [NSMutableArray new];
    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithTitle:@"Show" style:UIBarButtonItemStyleBordered target:self action:@selector(showMessages)]];
    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithTitle:@"Hide" style:UIBarButtonItemStyleBordered target:self action:@selector(hideMessages)]];
    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithTitle:@"Header On" style:UIBarButtonItemStyleBordered target:self action:@selector(addHeaderMessage)]];
    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithTitle:@"Header Off" style:UIBarButtonItemStyleBordered target:self action:@selector(removeHeaderMessage)]];
    [self.toolbar setItems:toolbarItems];
    [self.view addSubview:self.toolbar];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGRect toolbarFrame = CGRectZero;
    toolbarFrame.size.width = CGRectGetWidth(self.view.bounds);
    toolbarFrame.size.height = 44.0;
    toolbarFrame.origin.x = 0.0;
    toolbarFrame.origin.y = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(toolbarFrame);
    self.toolbar.frame = toolbarFrame;
    
    [self.or_messageController layoutMessagesAnimated:YES];
}

- (ORMessageExampleView*)createNewMessageViewWithText:(NSString*)text
{
    ORMessageExampleView* view = [[ORMessageExampleView alloc] initWithFrame:CGRectMake(0.0, 0.0, 280.0, 44.0)];
    view.backgroundColor = (self.or_messageController.messages.count % 2 == 0 ? [UIColor redColor] : [UIColor greenColor]);
    view.label.text = text;
    return view;
}

- (void)addMessage
{
    ORMessage* message = [ORMessage new];
    message.view = [self createNewMessageViewWithText:@"Hides when touched (Try toolbar actions)"];
    message.view.backgroundColor = [UIColor redColor];
    message.hidesWhenTouched = YES;
    message.padding = 5.0;
    message.inheritsWidthFromViewController = YES;
    message.identifiers = @[@"default"];
    message.animationOptions = ORMessageAnimationOptionFade | ORMessageAnimationOptionMove;
    message.touchedBlock = ^(ORMessage* _message) {
        // do something
    };
    
    [self.or_messageController addMessage:message animated:YES];
}

- (void)addMessageOnTop
{
    ORMessage* message = [ORMessage new];
    message.view = [self createNewMessageViewWithText:@"Hides when touched outside"];
    message.view.backgroundColor = [UIColor greenColor];
    message.showOnTop = YES;
    message.hidesWhenTouchedOutside = YES;
    message.padding = 5.0;
    message.identifiers = @[@"top"];
    message.animationOptions = ORMessageAnimationOptionFade | ORMessageAnimationOptionMove;
    [self.or_messageController addMessage:message animated:YES];
}

- (void)addMessageWithDuration
{
    ORMessage* message = [ORMessage new];
    message.view = [self createNewMessageViewWithText:@"Hides after 3 seconds"];
    message.view.backgroundColor = [UIColor lightGrayColor];
    message.showOnTop = YES;
    message.padding = 5.0;
    message.duration = 3.0;
    message.identifiers = @[@"duration"];
    message.animationOptions = ORMessageAnimationOptionFade | ORMessageAnimationOptionMove;
    
    message.touchedBlock = ^(ORMessage* _message) {
        // do something
    };
    message.touchedOutsideBlock = ^(ORMessage* _message) {
        // do something
    };
    
    [self.or_messageController addMessage:message animated:YES];
}

- (void)removeAllMessages
{
    [self.or_messageController removeMessagesWithIdentifiers:@[@"default", @"top", @"duration", @"header"] animated:YES];
}


//##################################################################
#pragma mark - Show / hide
//##################################################################
- (void)showMessages
{
    CGFloat offset = self.or_messageController.messagesOffsetTop;
    [self.or_messageController setMessagesOffsetTop:offset+10 animated:YES];
//    [self.or_messageController showMessagesWithIdentifiers:@[@"default"] animated:YES];
}

- (void)hideMessages
{
    CGFloat offset = self.or_messageController.messagesOffsetTop;
    [self.or_messageController setMessagesOffsetTop:offset-10 animated:YES];
//    [self.or_messageController hideMessagesWithIdentifiers:@[@"default"] animated:YES];
}


//##################################################################
#pragma mark - Header message
//##################################################################

- (void)addHeaderMessage
{
    ORMessage* message = [ORMessage new];
    message.view = [self createNewMessageViewWithText:@"Header"];
    message.view.backgroundColor = [UIColor yellowColor];
    message.padding = 5.0;
    message.identifiers = @[@"header"];
    message.animationOptions = ORMessageAnimationOptionFade | ORMessageAnimationOptionMove;
    
    message.touchedBlock = ^(ORMessage* _message) {
        // do something
    };
    message.touchedOutsideBlock = ^(ORMessage* _message) {
        // do something
    };
    
    [self.or_messageController addHeaderMessage:message animated:YES];
}

- (void)removeHeaderMessage
{
    [self.or_messageController removeHeaderMessageAnimated:YES];
}

@end
