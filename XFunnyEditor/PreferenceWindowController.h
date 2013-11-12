//
//  PreferenceWindowController.h
//  XFunnyEditor
//
//  Created by Kenji Abe on 2013/09/26.
//  Copyright (c) 2013年 STAR-ZERO. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol PreferenceDelegate <NSObject>

@required
- (void)selectedImageFile:(NSString *)imagePath;
- (void)selectedPosition:(NSImageAlignment)position;
- (void)selectedOpacity:(float)opacity;
- (void)selectedScaleFit:(BOOL)scaleFit;
@end

@interface PreferenceWindowController : NSWindowController<NSWindowDelegate>

@property (assign) IBOutlet NSTextField *textFile;
@property (assign) IBOutlet NSButton *buttonFile;
@property (assign) IBOutlet NSComboBox *comboPosition;
@property (assign) IBOutlet NSSlider *sliderOpacity;
@property (assign) IBOutlet NSTextField *labelOpacity;
@property (assign) IBOutlet NSButton *scaleFitButton;

@property (nonatomic, assign) id<PreferenceDelegate> delegate;

- (IBAction)clickFile:(id)sender;
- (IBAction)changePosition:(id)sender;
- (IBAction)changeSliderOpactiy:(id)sender;
- (IBAction)changeScaleFit:(id)sender;

@end
