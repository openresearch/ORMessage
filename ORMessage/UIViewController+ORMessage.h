//
//  UIViewController+ORMessage.h
//  ORMessage
//
//  Created by Robert Kramann on 10/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ORMessageController.h"

@interface UIViewController (ORMessage)

@property(readonly,nonatomic) ORMessageController* or_messageController;

- (void)or_willAddMessages:(NSArray*)messages animated:(BOOL)animated;

@end
