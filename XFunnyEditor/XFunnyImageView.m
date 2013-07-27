//
//  XFunnyImageView.m
//  XFunnyEditor
//
//  Created by Kenji Abe on 2013/07/28.
//  Copyright (c) 2013年 STAR-ZERO. All rights reserved.
//

#import "XFunnyImageView.h"

@implementation XFunnyImageView
{
    NSColor *_backgroundColor;
}

- (id)initWithFrame:(NSRect)frame backgroundColor:(NSColor *)backgroundColor
{
    self = [super initWithFrame:frame];
    if (self) {
        _backgroundColor = backgroundColor;
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [_backgroundColor setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

@end
