//
//  XFunnyEditor.m
//  XFunnyEditor
//
//  Created by Kenji Abe on 2013/07/27.
//  Copyright (c) 2013年 STAR-ZERO. All rights reserved.
//

#import "XFunnyEditor.h"

@interface XFunnyEditor()
- (XFunnyImageView *)getImageView:(NSView *)parentView;
- (NSRect)getImageViewFrame:(NSView *)scrollView;
@end

@implementation XFunnyEditor
{
    NSImage *_image;
    NSRect _sidebarRect;
    DVTSourceTextView *_currentTextView;
    NSColor *_originalColor;
}

NSString * const kUserDefaultsKeyImagePath = @"XFunnyEditoryImagePath";

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    NSLog(@"XFunnyEditor Plugin loaded");
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] init];
    });
}

- (id)init
{
    if (self = [super init]) {
        // Create menu items, initialize UI, etc.

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *imagePath = [userDefaults objectForKey:kUserDefaultsKeyImagePath];

        // Sample Menu Item:
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"XFunnyEditor" action:@selector(doMenuAction:) keyEquivalent:@""];
            [actionMenuItem setTarget:self];

            if (imagePath) {
                [actionMenuItem setState:NSOnState];
            } else {
                [actionMenuItem setState:NSOffState];
            }

            [[menuItem submenu] addItem:actionMenuItem];
            [actionMenuItem release];
        }

        if (imagePath) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:imagePath]) {
                _image = [[NSImage alloc] initWithContentsOfFile:imagePath];
            }
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];

    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewFrameDidChangeNotification:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:nil];
}

- (void)viewFrameDidChangeNotification:(NSNotification *)notification
{
    // keep current data
    if ([[notification object] isKindOfClass:[DVTSourceTextView class]]) {
        _currentTextView = (DVTSourceTextView *)[notification object];
    } else if ([[notification object] isKindOfClass:[DVTTextSidebarView class]]) {
        _sidebarRect = ((DVTTextSidebarView *)[notification object]).frame;
    }

    if (_image == nil) {
        return;
    }

    if ([[notification object] isKindOfClass:[DVTSourceTextView class]]) {
        DVTSourceTextView *textView = (DVTSourceTextView *)[notification object];
        DVTSourceTextScrollView *scrollView = (DVTSourceTextScrollView *)[textView enclosingScrollView];
        NSView *view = [scrollView superview];
        if (view) {
            if (NSEqualRects(_sidebarRect, NSZeroRect)) {
                return;
            }

            XFunnyImageView *imageView = [self getImageView:view];
            if (imageView) {
                // exist image
                [imageView setFrame:[self getImageViewFrame:scrollView]];
                return;
            }

            // create ImageView
            NSColor *color = [textView backgroundColor];
            _originalColor = color;
            [scrollView setDrawsBackground:NO];
            [textView setBackgroundColor:[NSColor clearColor]];

            imageView = [[[XFunnyImageView alloc] initWithFrame:[self getImageViewFrame:scrollView] backgroundColor:color] autorelease];

            [imageView setImage:_image];
            [view addSubview:imageView positioned:NSWindowBelow relativeTo:nil];
        }

    } else if ([[notification object] isKindOfClass:[DVTSourceTextScrollView class]]) {
        // resize editor
        DVTSourceTextScrollView *scrollView = [notification object];
        NSView *view = [scrollView superview];

        XFunnyImageView *imageView = [self getImageView:view];
        if (imageView) {
            [imageView setFrame:[self getImageViewFrame:scrollView]];
        }

    }
}

- (XFunnyImageView *)getImageView:(NSView *)parentView
{
    for (NSView *subView in [parentView subviews]) {
        if ([subView isKindOfClass:[NSImageView class]]) {
            return (XFunnyImageView *) subView;
        }
    }
    return nil;
}

- (NSRect)getImageViewFrame:(NSView *)scrollView
{
    return NSMakeRect(_sidebarRect.size.width,
                      0,
                      scrollView.bounds.size.width - _sidebarRect.size.width,
                      _sidebarRect.size.height);
}

// menu action
- (void)doMenuAction:(id)sender
{
    NSMenuItem *menuItem = (NSMenuItem *)sender;
    if ([menuItem state] == NSOnState){
        [self disableBackgroundImage:menuItem];
    } else {
        [self enableBackgroundImage:menuItem];
    }
}

// disable background image
- (void)disableBackgroundImage:(NSMenuItem *)menuItem
{
    DVTSourceTextScrollView *scrollView = (DVTSourceTextScrollView *)[_currentTextView enclosingScrollView];
    NSView *view = [scrollView superview];
    XFunnyImageView *imageView = [self getImageView:view];
    if (imageView) {
        // remove image
        [_currentTextView setBackgroundColor:_originalColor];
        [imageView removeFromSuperview];
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kUserDefaultsKeyImagePath];
    _image = nil;
    [menuItem setState:NSOffState];
}

// selection image file
- (void)enableBackgroundImage:(NSMenuItem *)menuItem
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSArray *fileTypes = [[NSArray alloc] initWithObjects:@"png", @"jpg", @"jpeg", nil];

    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowedFileTypes:fileTypes];

    [openPanel beginSheetModalForWindow:menuItem.view.window completionHandler:^(NSInteger resultCode){
        if (resultCode == NSOKButton) {
            NSURL *pathURL = [[openPanel URLs] objectAtIndex:0];
            NSString *imagePath = [pathURL path];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:imagePath forKey:kUserDefaultsKeyImagePath];
            [userDefaults synchronize];
            
            _image = [[NSImage alloc] initWithContentsOfFile:imagePath];

            if (_currentTextView) {
                // post notification
                [[NSNotificationCenter defaultCenter] postNotificationName:NSViewFrameDidChangeNotification object:_currentTextView];
            }

            [menuItem setState:NSOnState];

        }
    }];

}

- (void)dealloc
{
    [_image release];
    [_currentTextView release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
