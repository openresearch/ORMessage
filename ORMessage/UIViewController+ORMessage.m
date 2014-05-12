//
//  UIViewController+ORMessage.m
//  ORMessage
//
//  Created by Robert Kramann on 10/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import "UIViewController+ORMessage.h"

#import <objc/runtime.h>

static void* const ORMessageControllerObjectKey = "ORMessageControllerObjectKey";

@implementation UIViewController (ORMessage)

- (ORMessageController*)or_messageController
{
    ORMessageController* messageController = objc_getAssociatedObject(self, ORMessageControllerObjectKey);
    if (!messageController) {
        messageController = [[ORMessageController alloc] initWithViewController:self];
        objc_setAssociatedObject(self, ORMessageControllerObjectKey, messageController, OBJC_ASSOCIATION_RETAIN);
    }
    
    return messageController;
}


//##################################################################
#pragma mark - ORMessageControllerDelegate
//##################################################################

- (void)messageController:(ORMessageController *)messageController didAddHeaderMessage:(ORMessage *)message
{
    NSLog(@"didAddHeaderMessage");
}

- (void)messageController:(ORMessageController *)messageController didRemoveHeaderMessage:(ORMessage*)message
{
    NSLog(@"didRemoveHeaderMessage");
}

- (void)messageController:(ORMessageController *)messageController willShowHeaderMessage:(ORMessage *)message animated:(BOOL)animated
{
    NSLog(@"willShowHeaderMessage");
}

- (void)messageController:(ORMessageController *)messageController willHideHeaderMessage:(ORMessage *)message animated:(BOOL)animated
{
    NSLog(@"willHideHeaderMessage");
}

@end
