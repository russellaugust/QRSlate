//
//  Timecode.h
//  QRSlate_iOS
//
//  Created by August Anderson on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Timecode : NSObject {
    
}

- (NSString*) getTimecodeTODWithCentiseconds;
- (NSString*) timecodeFromTODatFramerate:(int)framerate;
- (NSString*) convertHHmmssSStoHHmmSSff:(NSString*)HHmmssSS withFramerate:(int)framerate;
- (NSString*) durationFromInpoint:(NSString*)inpoint toOutpoint:(NSString*)outpoint;
- (NSString*) convertFramesToTC:(int)totalFrames withFramerate:(int)fps;

@end
