//
//  CT_ScrollingTextView.h
//  ColorTracks
//
//  Created by Wolfgang Baird on 11/11/19.
//  Copyright © 2019 Wolfgang Baird. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CT_ScrollingTextView : NSView {
    NSTimer * scroller;
    NSPoint point;
    NSString * text;
    NSAttributedString * atttext;
    NSTimeInterval speed;
    CGFloat stringWidth;
}

@property (nonatomic, copy) NSString * text;
@property (nonatomic) NSTimeInterval speed;

- (void) setAttributedText:(NSAttributedString *)newText;

@end
