//
//  ORMessage_Private.h
//  ORMessage
//
//  Created by Robert Kramann on 10/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import "ORMessage.h"

@class ORMessageController;

@interface ORMessage ()

@property(weak) ORMessageController* messsageController;
@property(strong,nonatomic) NSTimer* timer;
@property(assign,nonatomic) BOOL isHeaderMessage;

@end
