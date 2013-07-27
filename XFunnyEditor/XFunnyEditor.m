//
//  XFunnyEditor.m
//  XFunnyEditor
//
//  Created by Kenji Abe on 2013/07/27.
//  Copyright (c) 2013年 STAR-ZERO. All rights reserved.
//

#import "XFunnyEditor.h"

@implementation XFunnyEditor
{
    NSImage *_image;
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

        // Sample Menu Item:
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"XFunnyEditor" action:@selector(doMenuAction:) keyEquivalent:@""];
            [actionMenuItem setTarget:self];
            [[menuItem submenu] addItem:actionMenuItem];
            [actionMenuItem release];
        }

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *imagePath = [userDefaults objectForKey:kUserDefaultsKeyImagePath];

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
    if (_image == nil) {
        return;
    }

    if ([[notification object] isKindOfClass:[DVTSourceTextView class]]) {
        DVTSourceTextView *textView = (DVTSourceTextView *)[notification object];
        NSScrollView *scrollView = [textView enclosingScrollView];
        NSView *view = [scrollView superview];
        if (view) {
            for (NSView *subView in [view subviews]) {
                if ([subView isKindOfClass:[NSImageView class]]) {
                    return;
                }
            }
            NSColor *color = [textView backgroundColor];
            [scrollView setDrawsBackground:NO];
            [textView setBackgroundColor:[NSColor clearColor]];

            XFunnyImageView *imageView = [[[XFunnyImageView alloc] initWithFrame:NSMakeRect(scrollView.frame.origin.x, scrollView.frame.origin.y, scrollView.bounds.size.width, scrollView.bounds.size.height) backgroundColor:color] autorelease];
            [imageView setImage:_image];
            [view addSubview:imageView positioned:NSWindowBelow relativeTo:nil];
        }
    }
}

// Sample Action, for menu item:
- (void)doMenuAction:(id)sender
{
    NSMenuItem *menuItem = (NSMenuItem *)sender;

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
        }
    }];
}

- (void)dealloc
{
    [_image release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
