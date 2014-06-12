//
//  ZXingReaderDevice.h
//  QRSlate_App
//
//  Created by August Anderson on 6/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <QTKit/QTKit.h>
#import <AVFoundation/AVFoundation.h>


@interface ZXingReaderDevice : NSObject {
@private
    
}

- (NSString*) movieFrameAsString:(CGImageRef)targetMovieFrame;

- (NSNumber*)frameRateOfMovie:(QTMovie*)mMovie;

- (NSDictionary*) quicktimeProcessorAndScanner:(NSString*)absoluteMoviePath 
                  qualityLevelOneThruThree:(int)qualityLevel;

- (CGImageRef)cgImageCreateFromCIImage:(CIImage *)ciImage;
- (CGImageRef)nsImageToCGImageRef:(NSImage*)image;
- (void) saveAsPNG:(NSImage*)image withName:(NSString*)filename;
- (CGImageRef) ciFiltersPass:(CIImage*)image;
- (BOOL) isDropFrame:(AVAssetTrack*)track;
- (NSNumber*) returnTimecodeInFrames:(AVAssetTrack*)track avAsset:(AVAsset*)videoAsset;

@end
