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

#import "NPWScrubber.h"
//#import "NPWNowPlayingController.h"

#import <QuartzCore/QuartzCore.h>

ColorTracks *plugin;

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

@interface ScrollingTextView : NSView {
    NSTimer * scroller;
    NSPoint point;
    NSString * text;
    NSAttributedString * atttext;
    NSTimeInterval speed;
    CGFloat stringWidth;
}

@property (nonatomic, copy) NSString * text;
@property (nonatomic) NSTimeInterval speed;

@end

@implementation ScrollingTextView

@synthesize text;
@synthesize speed;

- (void) dealloc {
    [scroller invalidate];
}

- (void) setText:(NSString *)newText {
    text = [newText copy];
    point = NSZeroPoint;

    stringWidth = [newText sizeWithAttributes:nil].width;

    if (scroller == nil && speed > 0 && text != nil) {
        scroller = [NSTimer scheduledTimerWithTimeInterval:speed target:self selector:@selector(moveText:) userInfo:nil repeats:YES];
    }
}

- (void) setAttributedText:(NSAttributedString *)newText {
    atttext = [newText copy];
    point = NSZeroPoint;
    
    stringWidth = atttext.size.width;

    if (scroller == nil && speed > 0 && atttext != nil) {
        scroller = [NSTimer scheduledTimerWithTimeInterval:speed target:self selector:@selector(moveText:) userInfo:nil repeats:YES];
    }
}

- (void) setSpeed:(NSTimeInterval)newSpeed {
    if (newSpeed != speed) {
        speed = newSpeed;

        [scroller invalidate];
        scroller = nil;
        if (speed > 0 && atttext != nil) {
            scroller = [NSTimer scheduledTimerWithTimeInterval:speed target:self selector:@selector(moveText:) userInfo:nil repeats:YES];
        } else if (speed > 0 && text != nil) {
            scroller = [NSTimer scheduledTimerWithTimeInterval:speed target:self selector:@selector(moveText:) userInfo:nil repeats:YES];
        }
    }
}

- (void) moveText:(NSTimer *)timer {
    point.x = point.x - 1.0f;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.

//    NSLog(@"ColorTracks : %f : %f", stringWidth, dirtyRect.size.width);
    
    if (stringWidth > dirtyRect.size.width) {
        dirtyRect.size.width = stringWidth;
    }
            
    if (point.x + stringWidth < 0) {
        if (stringWidth > dirtyRect.size.width) {
            point.x += stringWidth;
        } else {
            point.x += dirtyRect.size.width;
        }
//        point.x += dirtyRect.size.width;
    }
    
    [atttext drawAtPoint:point];
//    [text drawAtPoint:point withAttributes:nil];

    if (point.x < 0) {
        NSPoint otherPoint = point;
        
        if (stringWidth > dirtyRect.size.width) {
            otherPoint.x += stringWidth;
        } else {
            otherPoint.x += dirtyRect.size.width;
        }
        
        [atttext drawAtPoint:otherPoint];
//        [text drawAtPoint:otherPoint withAttributes:nil];
    }
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
    
    // ColorTracks
    NSImage  *currentImage;
    NSString *currentTrack;
    ScrollingTextView *scrollTxt;

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
}

- (void)goUp:(NSView*)v {
    if (v.superview) {
        [self goUp:v.superview];
    } else {
        [self goDown:v];
        v.wantsLayer = true;
        v.layer.backgroundColor = NSColor.redColor.CGColor;
    }
}

- (void)goDown:(NSView*)v {
    for (NSView *sv in v.subviews) {
        sv.wantsLayer = true;
        sv.layer.backgroundColor = NSColor.redColor.CGColor;
        [self goDown:sv];
        NSLog(@"ColorTracks : %@", v);
    }
}

- (void)_updateArtistAndTrackName {
    ZKOrig(void);

    if (!scrollTxt) {
        scrollTxt = [[ScrollingTextView alloc] init];
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
        
    if (_albumImageView.image) {
                    
        // Has albumn image
        if ([[self valueForKey:@"nowPlayingController"] valueForKey:@"albumImage"]) {
            
            // Only call once per track
            if (![currentImage isEqualTo:_albumImageView.image]) {
                currentImage = _albumImageView.image;
                SLColorArt *colorArt = [[SLColorArt alloc] initWithImage:currentImage scaledSize:NSMakeSize(100., 100.)];
                //        self.imageView.image = colorArt.scaledImage;
                self.view.layer.backgroundColor = [colorArt.backgroundColor colorWithAlphaComponent:0.22].CGColor;
                
                [_scanBackwardButton setImage:[_scanBackwardButton.image imageTintedWithColor:colorArt.primaryColor]];
                [_scanForwardButton setImage:[_scanForwardButton.image imageTintedWithColor:colorArt.primaryColor]];
                
                [_playPauseButton setImage:[_playPauseButton.image imageTintedWithColor:colorArt.primaryColor]];
                [_playPauseButton setAlternateImage:[_playPauseButton.alternateImage imageTintedWithColor:colorArt.primaryColor]];
                
                _trackTextField.textColor = colorArt.primaryColor;
                _artistTextField.textColor = colorArt.secondaryColor;
                
                _remainingTimeTextField.textColor = colorArt.detailColor;
                _elapsedTimeTextField.textColor = colorArt.detailColor;
                
                if (_trackTextField.attributedStringValue.length > 0)
                    [scrollTxt setAttributedText:_trackTextField.attributedStringValue];
            }
            
        } else {
            
            // No aldumn art so set to fit well with systm color
            [self adjustWithSystemColor];
        
        }
        
    } else {
        
        // No aldumn art so set to fit well with systm color
        [self adjustWithSystemColor];
        
    }
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
