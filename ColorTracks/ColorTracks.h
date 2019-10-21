//
//  ColorTracks.h
//  ColorTracks
//
//  Created by Wolfgang Baird on 10/19/19.
//Copyright © 2019 Wolfgang Baird. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ColorTracks : NSObject

@property NSArray *lightColors;
@property NSArray *darkColors;

+ (instancetype)sharedInstance;

@end
