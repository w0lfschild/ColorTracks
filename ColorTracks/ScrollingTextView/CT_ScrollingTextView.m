//
//  CT_ScrollingTextView.m
//  ColorTracks
//
//  Created by Wolfgang Baird on 11/11/19.
//  Copyright © 2019 Wolfgang Baird. All rights reserved.
//

#import "CT_ScrollingTextView.h"

@implementation CT_ScrollingTextView

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
