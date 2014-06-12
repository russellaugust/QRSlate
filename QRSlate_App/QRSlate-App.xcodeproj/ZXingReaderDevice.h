//
//  ZXingReaderDevice.h
//  QRSlate_App
//
//  Created by August Anderson on 6/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ZXingReaderDevice : NSObject {
@private
    
    int totalDurationInFrames;
    int qrcodeMarker;
    int timebase;
    
}

@property (nonatomic) int totalDurationInFrames;
@property (nonatomic) int qrcodeMarker;
@property (nonatomic) int timebase;

- (NSString*) movieFrameAsString:(CGImageRef)targetMovieFrame;

- (NSString*) quicktimeProcessorAndScanner:(NSString*)absoluteMoviePath qualityLevelOneThruThree:(int)qualityLevel 
                                                                               sessionAttributes:(NSDictionary*)sessAttrib;
- (CGImageRef)cgImageCreateFromCIImage:(CIImage *)ciImage;
- (CGImageRef)nsImageToCGImageRef:(NSImage*)image;
- (void) saveAsPNG:(NSImage*)theInput;
- (CGImageRef) ciFiltersPass:(CIImage*)image;
- (int) createFormattedTimebaseFromQTAttribute:(NSNumber*)qtmediatimescaleattribute;

@end
