//
//  XFunnyEditor.m
//  XFunnyEditor
//
//  Created by Kenji Abe on 2013/07/27.
//  Copyright (c) 2013年 STAR-ZERO. All rights reserved.
//

#import "XFunnyEditor.h"

@interface XFunnyEditor()
@end

@implementation XFunnyEditor
{
    PreferenceWindowController *_preferenceWindow;
    NSImage *_image;
    NSUInteger _position;
    float _opacity;
    BOOL _scaleFit;
    NSRect _sidebarRect;
    DVTSourceTextView *_currentTextView;
    NSColor *_originalColor;

    BOOL _isXVimInstalled;
    CGFloat _editorViewHeight;
}

NSString * const kUserDefaultsKeyImagePath = @"XFunnyEditoryImagePath";
NSString * const kUserDefaultsKeyImagePosition = @"XFunnyEditoryImagePosition";
NSString * const kUserDefaultsKeyImageOpcity = @"XFunnyEditoryImageOpacity";
NSString * const kUserDefaultsKeyImageScaleFit = @"XFunnyEditoryImageScaleFit";
NSString * const kXVimInstallPath = @"Library/Application Support/Developer/Shared/Xcode/Plug-ins/XVim.xcplugin";
CGFloat const kXVimCommandLineHeight = 18.0;

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

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *imagePath = [userDefaults objectForKey:kUserDefaultsKeyImagePath];
        
        if (imagePath) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:imagePath]) {
                _image = [[NSImage alloc] initWithContentsOfFile:imagePath];
            } else {
                [self removeUserDefaults];
            }
        }
        
        _position = [userDefaults integerForKey:kUserDefaultsKeyImagePosition];
        _opacity = [userDefaults floatForKey:kUserDefaultsKeyImageOpcity];
        _scaleFit = [userDefaults boolForKey:kUserDefaultsKeyImageScaleFit];
        _isXVimInstalled = [self isXVimInstalled];
        
        if (_opacity == 0) {
            _opacity = 1;
        }
        
        // Sample Menu Item:
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"XFunnyEditor" action:@selector(doMenuAction:) keyEquivalent:@""];
            [actionMenuItem setTarget:self];

            if (_image) {
                [actionMenuItem setState:NSOnState];
            } else {
                [actionMenuItem setState:NSOffState];
            }

            [[menuItem submenu] addItem:actionMenuItem];
            [actionMenuItem release];
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
    // keep current object
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

            NSImageView *imageView = [self getImageViewFromParentView:view];
            XFunnyBackgroundView *backgroundView = [self getBackgroundViewFromaParentView:view];
            if (imageView) {
                // exist image
                [self setFrameImageView:imageView backgroundView:backgroundView scrollView:scrollView];
                [imageView setImage:_image];
                return;
            }

            NSColor *color = [textView backgroundColor];
            _originalColor = color;
            [scrollView setDrawsBackground:NO];
            [textView setBackgroundColor:[NSColor clearColor]];

            _editorViewHeight = view.frame.size.height;
            if (_isXVimInstalled) {
                _editorViewHeight -= kXVimCommandLineHeight;
            }

            // create ImageView
            imageView = [[[NSImageView alloc] initWithFrame:[self getImageViewFrame:scrollView]] autorelease];
            
            backgroundView = [[[XFunnyBackgroundView alloc] initWithFrame:[self getImageViewFrame:scrollView] color:color] autorelease];

            [imageView setImage:_image];
            imageView.alphaValue = _opacity;
            imageView.imageAlignment = _position;
            if (_scaleFit) {
                [imageView setImageScaling:NSScaleToFit];
            }
            [view addSubview:imageView positioned:NSWindowBelow relativeTo:nil];
            [view addSubview:backgroundView positioned:NSWindowBelow relativeTo:nil];
        }

    } else if ([[notification object] isKindOfClass:[DVTSourceTextScrollView class]]) {
        // resize editor
        DVTSourceTextScrollView *scrollView = [notification object];
        NSView *view = [scrollView superview];

        NSImageView *imageView = [self getImageViewFromParentView:view];
        XFunnyBackgroundView *backgroundView = [self getBackgroundViewFromaParentView:view];

        _editorViewHeight = view.frame.size.height;
        if (_isXVimInstalled) {
            _editorViewHeight -= kXVimCommandLineHeight;
        }

        // set frame
        [self setFrameImageView:imageView backgroundView:backgroundView scrollView:scrollView];
    }
}

- (NSImageView *)getImageViewFromParentView:(NSView *)parentView
{
    for (NSView *subView in [parentView subviews]) {
        if ([subView isKindOfClass:[NSImageView class]]) {
            return (NSImageView *) subView;
        }
    }
    return nil;
}

- (NSImageView *)getImageViewFromTextView
{
    
    DVTSourceTextScrollView *scrollView = (DVTSourceTextScrollView *)[_currentTextView enclosingScrollView];
    NSView *view = [scrollView superview];
    if (view) {
        return [self getImageViewFromParentView:view];
    }
    
    return nil;
}

- (XFunnyBackgroundView *)getBackgroundViewFromaParentView:(NSView *)parentView
{
    for (NSView *subView in [parentView subviews]) {
        if ([subView isKindOfClass:[XFunnyBackgroundView class]]) {
            return (XFunnyBackgroundView *) subView;
        }
    }
    return nil;
}

- (NSRect)getImageViewFrame:(NSView *)scrollView
{
    CGFloat y = 0;
    if (_isXVimInstalled) {
        y += kXVimCommandLineHeight;
    }

    return NSMakeRect(_sidebarRect.size.width,
                      y,
                      scrollView.bounds.size.width - _sidebarRect.size.width,
                      _editorViewHeight);
}

- (void)setFrameImageView:(NSImageView *)imageView backgroundView:(XFunnyBackgroundView *)backgroundView scrollView:(DVTSourceTextScrollView *)scrollView
{
    if (imageView && backgroundView) {
        [imageView setFrame:[self getImageViewFrame:scrollView]];
        [backgroundView setFrame:[self getImageViewFrame:scrollView]];
        if (_isXVimInstalled) {
            CGRect scrollViewFrame = scrollView.frame;
            [scrollView setFrame:CGRectMake(scrollViewFrame.origin.x,
                                            kXVimCommandLineHeight,
                                            scrollViewFrame.size.width,
                                            _editorViewHeight)];
        }
    }
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
    NSImageView *imageView = [self getImageViewFromParentView:view];
    XFunnyBackgroundView *backgroundView = [self getBackgroundViewFromaParentView:view];
    if (imageView) {
        // remove image
        [_currentTextView setBackgroundColor:_originalColor];
        [imageView removeFromSuperview];
        [backgroundView removeFromSuperview];
    }

    [self removeUserDefaults];
    
    if (_image) {
        [_image release];
        _image = nil;
    }
    _position = 0;
    _opacity = 1;
    [menuItem setState:NSOffState];
}

// selection image file
- (void)enableBackgroundImage:(NSMenuItem *)menuItem
{
    
    if (!_preferenceWindow) {
        _preferenceWindow = [[PreferenceWindowController alloc] initWithWindowNibName:@"PreferenceWindowController"];
        _preferenceWindow.delegate = self;
    }
    [_preferenceWindow.textFile setStringValue:@""];
    [_preferenceWindow.comboPosition selectItemAtIndex:0];
    [_preferenceWindow.sliderOpacity setIntValue:100];
    [_preferenceWindow.labelOpacity setStringValue:@"100"];
    
    NSInteger result = [[NSApplication sharedApplication] runModalForWindow:[_preferenceWindow window]];
    [[_preferenceWindow window] orderOut:self];
    
    if (result == 0) {
        [menuItem setState:NSOnState];
        
        // save userdefaults
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:_preferenceWindow.textFile.stringValue forKey:kUserDefaultsKeyImagePath];
        [userDefaults setInteger:_position forKey:kUserDefaultsKeyImagePosition];
        [userDefaults setFloat:_opacity forKey:kUserDefaultsKeyImageOpcity];
        [userDefaults setBool:_scaleFit forKey:kUserDefaultsKeyImageScaleFit];
        [userDefaults synchronize];
    }

}

- (void)removeUserDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kUserDefaultsKeyImagePath];
    [userDefaults removeObjectForKey:kUserDefaultsKeyImagePosition];
    [userDefaults removeObjectForKey:kUserDefaultsKeyImageOpcity];
    [userDefaults removeObjectForKey:kUserDefaultsKeyImageScaleFit];
    [userDefaults synchronize];
    
}

- (void)selectedImageFile:(NSString *)imagePath
{
    _image = [[NSImage alloc] initWithContentsOfFile:imagePath];
    if (_currentTextView) {
        // post notification
        [[NSNotificationCenter defaultCenter] postNotificationName:NSViewFrameDidChangeNotification object:_currentTextView];
    }
}

- (void)selectedPosition:(NSImageAlignment)position
{
    _position = position;
    NSImageView *imageView = [self getImageViewFromTextView];
    if (imageView) {
        imageView.imageAlignment = position;
    }
    
}
- (void)selectedOpacity:(float)opacity
{
    _opacity = opacity;
    NSImageView *imageView = [self getImageViewFromTextView];
    if (imageView) {
        imageView.alphaValue = opacity;
    }
}

- (void)selectedScaleFit:(BOOL)scaleFit
{
    _scaleFit = scaleFit;
    NSImageView *imageView = [self getImageViewFromTextView];
    if (imageView) {
        if (scaleFit) {
            [imageView setImageScaling:NSScaleToFit];
        } else {
            [imageView setImageScaling:NSScaleNone];
        }
    }
}

- (BOOL)isXVimInstalled
{
    NSString *pluginsInstallPath = [NSHomeDirectory() stringByAppendingPathComponent:kXVimInstallPath];
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];

    return [fileManager fileExistsAtPath:pluginsInstallPath];
}

- (void)dealloc
{
    [_image release];
    [_currentTextView release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
