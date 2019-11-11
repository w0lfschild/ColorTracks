//
//  ColorTracks.m
//  ColorTracks
//
//  Created by Wolfgang Baird on 10/19/19.
//Copyright © 2019 Wolfgang Baird. All rights reserved.
//

@import AppKit;

#import "ColorTracks.h"
#import "SLColorArt.h"
#import "CT_ScrollingTextView.h"
#import "AYProgressIndicator.h"

#import "NPWScrubber.h"
//#import "NPWNowPlayingController.h"

#import <QuartzCore/QuartzCore.h>

ColorTracks *plugin;
NSImage  *currentImage;
NSString *currentTrack;
CT_ScrollingTextView *scrollTxt;
AYProgressIndicator *colorProgress;
SLColorArt *currentArt;

@interface NSImage (ImageAdditions)
@end

@implementation NSImage (ImageAdditions)

- (NSImage *)imageTintedWithColor:(NSColor *)tint {
    NSImage *image = self.copy;
    [image lockFocus];
    [tint set];
    NSRectFillUsingOperation(CGRectMake(0, 0, image.size.width, image.size.height), NSCompositingOperationSourceAtop);
    [image unlockFocus];
    image.template = false;
    return image;
}

@end



@interface ColorTracks_NPWNowPlayingViewController : NSViewController
{
    // Stock
    NSButton *_playPauseButton;
    NSButton *_scanForwardButton;
    NSButton *_scanBackwardButton;
    NSImageView *_albumImageView;
    NSTextField *_trackTextField;
    NSTextField *_artistTextField;
    NSTextField *_remainingTimeTextField;
    NSTextField *_elapsedTimeTextField;
    NPWScrubber *_scrubber;
//    NPWNowPlayingController *_nowPlayingController;
}
//@property(retain, nonatomic) NPWNowPlayingController *nowPlayingController;
- (void)_updateAlbumImage;
@end

@implementation ColorTracks_NPWNowPlayingViewController

- (void)adjustWithSystemColor {
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    NSColor *primary = NSColor.blackColor;
    NSColor *secondary = NSColor.darkGrayColor;
    NSColor *highlight = NSColor.lightGrayColor;
    if (NSProcessInfo.processInfo.operatingSystemVersion.minorVersion >= 14) {
        if ([osxMode isEqualToString:@"Dark"]) {
            primary = NSColor.whiteColor;
            secondary = NSColor.lightGrayColor;
            highlight = NSColor.darkGrayColor;
        }
    }
    
    self.view.layer.backgroundColor = NSColor.clearColor.CGColor;
    
    [_scanBackwardButton setImage:[_scanBackwardButton.image imageTintedWithColor:primary]];
    [_scanForwardButton setImage:[_scanForwardButton.image imageTintedWithColor:primary]];
    [_playPauseButton setImage:[_playPauseButton.image imageTintedWithColor:primary]];
    [_playPauseButton setAlternateImage:[_playPauseButton.alternateImage imageTintedWithColor:primary]];
    
    _trackTextField.textColor = primary;
    _artistTextField.textColor = secondary;
    
    _remainingTimeTextField.textColor = secondary;
    _elapsedTimeTextField.textColor = secondary;
    
    if (colorProgress) {
        [colorProgress setProgressColor:primary];
        [colorProgress setEmptyColor:secondary];
    }
}

- (void)adjustViewToMatch {
    if (_albumImageView.image) {
                        
        // Has albumn image
        if ([[self valueForKey:@"nowPlayingController"] valueForKey:@"albumImage"]) {
            
            // Only call once per track
            if (![currentImage isEqualTo:_albumImageView.image]) {
            
                currentImage = _albumImageView.image;
                
                currentArt = [[SLColorArt alloc] initWithImage:currentImage scaledSize:NSMakeSize(100., 100.)];
//                self.view.layer.contents = colorArt.scaledImage;
                self.view.layer.backgroundColor = [currentArt.backgroundColor colorWithAlphaComponent:1.0].CGColor;

                [_scanBackwardButton setImage:[_scanBackwardButton.image imageTintedWithColor:currentArt.primaryColor]];
                [_scanForwardButton setImage:[_scanForwardButton.image imageTintedWithColor:currentArt.primaryColor]];

                [_playPauseButton setImage:[_playPauseButton.image imageTintedWithColor:currentArt.primaryColor]];
                [_playPauseButton setAlternateImage:[_playPauseButton.alternateImage imageTintedWithColor:currentArt.primaryColor]];

                _trackTextField.textColor = currentArt.primaryColor;
                _artistTextField.textColor = currentArt.secondaryColor;

                _remainingTimeTextField.textColor = currentArt.detailColor;
                _elapsedTimeTextField.textColor = currentArt.detailColor;
                
                if (_trackTextField.attributedStringValue.length > 0)
                    [scrollTxt setAttributedText:_trackTextField.attributedStringValue];
            }
            
            // Adjust the progress color just incase
            if (currentArt) {
                [colorProgress setProgressColor:currentArt.primaryColor];
                [colorProgress setEmptyColor:currentArt.secondaryColor];
            }
            
        } else {
            
            // No albumn art so set to fit well with systm color
            [self adjustWithSystemColor];
        
        }
        
    } else {
        
        // No albumn art so set to fit well with systm color
        [self adjustWithSystemColor];
        
    }
}

- (void)_updateScrubber {
    ZKOrig(void);
    
    if (!colorProgress) {
        //    {{16, 67}, {288, 6}}
        NSRect indiFrame = CGRectMake(16, 69, 288, 2);
        colorProgress = [[AYProgressIndicator alloc] initWithFrame:indiFrame
                                            progressColor:[NSColor systemPinkColor]
                                               emptyColor:[NSColor systemBlueColor]
                                                 minValue:0
                                                 maxValue:1
                                             currentValue:0];
        [colorProgress setHidden:NO];
        [colorProgress setWantsLayer:YES];
        [colorProgress.layer setCornerRadius:2];
        [[self view] addSubview:colorProgress];
        [[self view] addSubview:colorProgress positioned:NSWindowBelow relativeTo:_scrubber];
    }
    
    [self adjustViewToMatch];
    
    [_scrubber setAlphaValue:0];
    colorProgress.doubleValue = _scrubber.doubleValue / _scrubber.maxValue;
}

- (void)_scrubberDragged:(id)arg1 {
//    NSLog(@"colortracks : %@", arg1);
    colorProgress.doubleValue = _scrubber.doubleValue / _scrubber.maxValue;
    ZKOrig(void, arg1);
}

- (void)_updateArtistAndTrackName {
    ZKOrig(void);

    if (!scrollTxt) {
        scrollTxt = [[CT_ScrollingTextView alloc] init];
        [scrollTxt setFrame:_trackTextField.frame];
        [_trackTextField.superview addSubview:scrollTxt];
        [scrollTxt setText:@""];
        [scrollTxt setSpeed:0.04]; //redraws every 1/100th of a second
    }

    NSRect expansionRect = [[_trackTextField cell] expansionFrameWithFrame:_trackTextField.visibleRect inView:_trackTextField];
    BOOL truncating = !NSEqualRects(NSZeroRect, expansionRect);

    if (_trackTextField.attributedStringValue.length > 0)
        [scrollTxt setAttributedText:_trackTextField.attributedStringValue];

    CGRect frm = _trackTextField.frame;
    frm.origin = CGPointMake(0, 21);
    [scrollTxt setFrame:frm];

    if (truncating) {
        [scrollTxt setHidden:false];
        [_trackTextField setHidden:true];
    } else {
        [scrollTxt setHidden:true];
        [_trackTextField setHidden:false];
    }
}

- (void)_updateAlbumImage {
    ZKOrig(void);
    [self adjustViewToMatch];
}

@end

@interface ColorTracks()
@end

@implementation ColorTracks

+ (instancetype)sharedInstance {
    static ColorTracks *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

+ (void)load {
//    NSLog(@"ColorTracks : %@", NSBundle.mainBundle.bundleIdentifier);
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple..NowPlayingWidgetContainer.NowPlayingWidget"]) {
        plugin = [ColorTracks sharedInstance];
        plugin.lightColors = @[NSColor.blackColor, NSColor.grayColor];
        plugin.darkColors = @[NSColor.whiteColor, NSColor.grayColor];
        ZKSwizzle(ColorTracks_NPWNowPlayingViewController, NPWNowPlayingViewController);
        NSUInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
        NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
    }
}

@end
