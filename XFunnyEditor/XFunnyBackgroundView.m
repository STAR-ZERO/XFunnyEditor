//
//  XFunnyBackground.m
//  XFunnyEditor
//
//  Created by Kenji Abe on 2013/09/26.
//  Copyright (c) 2013年 STAR-ZERO. All rights reserved.
//

#import "XFunnyBackgroundView.h"

@implementation XFunnyBackgroundView
{
    NSColor *_backgroundColor;
}

- (id)initWithFrame:(NSRect)frame color:(NSColor *)aColor
{
   self = [super initWithFrame:frame];
    if (self) {
        _backgroundColor = aColor;
        [_backgroundColor retain];
    }
    return self;
    
}
- (void)drawRect:(NSRect)dirtyRect
{
    [_backgroundColor setFill];
    NSRectFill(dirtyRect);
	[super drawRect:dirtyRect];
}

- (void)dealloc
{
    [_backgroundColor release];
    [super dealloc];
}
@end
