//
//  PreferenceWindowController.m
//  XFunnyEditor
//
//  Created by Kenji Abe on 2013/09/26.
//  Copyright (c) 2013年 STAR-ZERO. All rights reserved.
//

#import "PreferenceWindowController.h"

@interface PreferenceWindowController ()

@end

@implementation PreferenceWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
}

- (void)windowWillClose:(NSNotification *)notification
{
    int result = 1;
    if (self.textFile && ![self.textFile.stringValue isEqualToString:@""]) {
        // result ok
        result = 0;
    }
    [[NSApplication sharedApplication] stopModalWithCode:result];
}

- (IBAction)clickFile:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSArray *fileTypes = [[[NSArray alloc] initWithObjects:@"png", @"jpg", @"jpeg", nil] autorelease];

    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowedFileTypes:fileTypes];

    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger resultCode){
        if (resultCode == NSOKButton) {
            NSURL *pathURL = [[openPanel URLs] objectAtIndex:0];
            NSString *imagePath = [pathURL path];
            
            [self.textFile setStringValue:imagePath];
            
            [self.delegate selectedImageFile:imagePath];
        }
    }];
}

- (IBAction)changePosition:(id)sender {
    NSInteger index = [self.comboPosition indexOfSelectedItem];
    [self.delegate selectedPosition:index];
}

- (IBAction)changeSliderOpactiy:(id)sender {
    NSUInteger opacity = floor([self.sliderOpacity floatValue]);
    [self.labelOpacity setStringValue:[NSString stringWithFormat:@"%ld", opacity]];
    
    [self.delegate selectedOpacity:opacity / 100.0];
}

- (IBAction)changeScaleFit:(id)sender {
    BOOL scaleFit;
    if ([self.scaleFitButton state] == NSOnState) {
        scaleFit = YES;
    }
    else {
        scaleFit = NO;
    }
    
    [self.delegate selectedScaleFit:scaleFit];
}

@end
