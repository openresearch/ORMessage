//
//  ORMessageExampleView.m
//  ORMessageExample
//
//  Created by Robert Kramann on 10/05/14.
//  Copyright (c) 2014 OpenResearch Software Development OG. All rights reserved.
//

#import "ORMessageExampleView.h"

@implementation ORMessageExampleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.label = [[UILabel alloc] initWithFrame:CGRectZero];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
        self.label.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.label];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.label.frame = self.bounds;
}

@end
