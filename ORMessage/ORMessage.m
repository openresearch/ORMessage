//
//  ORMessage.m
//  ORMessage
//
//  Created by Robert Kramann on 09/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import "ORMessage_Private.h"

#import "ORMessageController.h"


@implementation ORMessage

- (void)removeAnimated:(BOOL)animated
{
    [self.messsageController removeMessage:self animated:animated];
}

- (void)removeAfterDelay:(NSTimeInterval)delay animated:(BOOL)animated
{
    __weak ORMessage* weak_self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weak_self.messsageController removeMessage:weak_self animated:animated];
    });
}


@end
