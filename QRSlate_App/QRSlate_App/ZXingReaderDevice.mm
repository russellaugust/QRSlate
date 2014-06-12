//
//  ZXingReaderDevice.m
//  QRSlate_App
//
//  Created by August Anderson on 6/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ZXingReaderDevice.h"
#import "QTTimeConvert.h"

#import <ZXing/ZXResult.h>
#import <ZXing/ZXImage.h>
#import <ZXing/ZXBinaryBitmap.h>
#import <ZXing/ZXReader.h>
#import <ZXing/ZXCGImageLuminanceSource.h>
#import <ZXing/ZXHybridBinarizer.h>
#import <ZXing/ZXQRCodeReader.h>
#import <ZXing/ZXDecodeHints.h>
#import <ZXing/ZXReaderException.h>
#import <ZXing/ZXIllegalArgumentException.h>


@implementation ZXingReaderDevice

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}


//------------------------------------------------------------------------------------------------------------------------
//Receives a CGImageRef and scans it for a QR Code, then returns an NSString upon FIRST SUCCESSFUL result and ends the search.
- (NSString*) movieFrameAsString:(CGImageRef)targetMovieFrame
{
    @try 
    {        
        ZXCGImageLuminanceSource* luminancesource = [[ZXCGImageLuminanceSource alloc] initWithCGImage:targetMovieFrame];
        ZXHybridBinarizer* binarizerInput = [[ZXHybridBinarizer alloc] init];
        [binarizerInput initWithSource:luminancesource];
        ZXBinaryBitmap* binarybitmapInput = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizerInput];
        ZXDecodeHints* decodehints   = [[ZXDecodeHints alloc] init];
        ZXQRCodeReader* qrcodereader = [[ZXQRCodeReader alloc] init];
        
        ZXResult* results = [qrcodereader decode:binarybitmapInput hints:decodehints];
                
        [luminancesource release];
        [binarizerInput release];
        [binarybitmapInput release];
        [decodehints release];
        [qrcodereader release];
                
        return [results text];
    }
    
    @catch (ZXReaderException* rex) {
        if (![rex.reason isEqualToString:@"Could not find three finder patterns"]) {
            //NSLog(@"failed to decode, caught ReaderException '%@'", rex.reason);
        }
    } 
    
    @catch (ZXIllegalArgumentException* iex) {
        //NSLog(@"failed to decode, caught IllegalArgumentException '%@'", iex.reason);
    }
    
    @catch (id ue) {
        //NSLog(@"Caught unknown exception: %@", ue);
    }
        
    return 0;
}

//------------------------------------------------------------------------------------------------------------------------
// Inputs a QUICKTIME, processes the image with filters, runs it through ZXing, and returns the result as an NSString
- (NSDictionary*) quicktimeProcessorAndScanner:(NSString*)absoluteMoviePath qualityLevelOneThruThree:(int)qualityLevel
{
    int totalDurationInFrames;
    int timebase;
    NSNumber *fps = [[NSNumber alloc] init];
    NSNumber *samples = [[NSNumber alloc] init];
    NSNumber *videoTimeScale = [[NSNumber alloc] init];
    NSNumber *videoTimeValue = [[NSNumber alloc] init];
    NSNumber *audioTimeScale = [[NSNumber alloc] init];
    NSNumber *audioTimeValue = [[NSNumber alloc] init];
    BOOL timecodeIsDropFrame = 0;
    NSNumber *timecodeStartInFrames = [[NSNumber alloc] init];
    
    // Load Movie File
    QTMovie *movieFile = [QTMovie movieWithFile:absoluteMoviePath error:NULL];

    // Create Track to pull metadata from. 
    NSArray *tracks = [movieFile tracks];
    NSString* timeIncrementString = [[NSString alloc] init];
    
    // Iterate through metadata.
    for(QTTrack *track in tracks)
    {
        QTMedia *media = [track media];
        
        // Checks to make sure the quicktime media being inputted has a video track.
        if([[media attributeForKey:QTMediaTypeAttribute] isEqualToString:QTMediaTypeVideo])
        {
            samples = [media attributeForKey:QTMediaSampleCountAttribute];
            
            // Returns the total number of frames.
            totalDurationInFrames = (NSInteger)[samples integerValue];

            videoTimeScale = [media attributeForKey:QTMediaTimeScaleAttribute];
            
            // Sets the Time Increment using the timescale.
            timeIncrementString = [[NSString alloc] initWithFormat:@"00:00:00:01.0000/%ld", (NSInteger)[videoTimeScale integerValue]];            
            
            NSValue *duration = [media attributeForKey:QTMediaDurationAttribute];
            QTTime dur = [duration QTTimeValue];
            videoTimeValue = [NSNumber numberWithLongLong:dur.timeValue];
            
            // Returns the framerate as a timebase.
            fps = [self frameRateOfMovie:movieFile];
            timebase = round([fps doubleValue]);
        }
        
        // Checks to make sure the quicktime media being inputted has a audio track.
        if([[media attributeForKey:QTMediaTypeAttribute] isEqualToString:QTMediaTypeSound])
        {
            NSValue *duration = [media attributeForKey:QTMediaDurationAttribute];
            QTTime dur = [duration QTTimeValue];
            audioTimeScale = [NSNumber numberWithLongLong:dur.timeScale];
            audioTimeValue = [NSNumber numberWithLongLong:dur.timeValue];
        }
        
        // Searching for Timecode and DF/NDF
        if([[media attributeForKey:QTMediaTypeAttribute] isEqualToString:QTMediaTypeTimeCode]) {
            NSURL *url = [NSURL fileURLWithPath:absoluteMoviePath];
            AVAsset *videoAsset = [AVAsset assetWithURL:url];
            
            for (AVAssetTrack * track in [videoAsset tracks]) {
                if ([[track mediaType] isEqualToString:AVMediaTypeTimecode]) {
                    timecodeIsDropFrame = [self isDropFrame:track];
                    timecodeStartInFrames = [self returnTimecodeInFrames:track avAsset:videoAsset];
                }
            }
        }
        
        if (timecodeStartInFrames == nil)
            timecodeStartInFrames = [[NSNumber alloc] initWithInt:0];
    }
    
    QTTime timeIncrementer = QTTimeFromString(timeIncrementString);
    [timeIncrementString release];
    QTTime time = [movieFile currentTime];
    
    NSSize movieOriginalSize = [[movieFile attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
    
    // Decreases the resolution of the image based on the user input for Quality.
    int x; int y;
    if (qualityLevel == 0)
    {
        x = movieOriginalSize.width / 1;
        y = movieOriginalSize.height / 1;
    }
    else if (qualityLevel == 1)
    {
        x = movieOriginalSize.width / 2;
        y = movieOriginalSize.height / 2;
    }
    else if (qualityLevel == 2)
    {
        x = movieOriginalSize.width / 3;
        y = movieOriginalSize.height / 3;
    }
    
    NSSize movieNewSize = NSMakeSize(x, y);
    NSValue *movieNewValue = [NSValue valueWithSize:movieNewSize];
    
    // Initializes the attributes for the image still pulled from the Quicktime video.
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:movieNewValue forKey:QTMovieFrameImageSize];
    [attributes setObject:QTMovieFrameImageTypeCGImageRef forKey:QTMovieFrameImageType];

    CGImageRef theImage;
    BOOL exitNow = NO;
    NSString *theResult = NULL;
    
    //Scans through QT Frames incrementing by timeIncrementer
    while (exitNow==NO)
    {
        time = QTTimeIncrement(time, timeIncrementer);
        theImage = (CGImageRef)[movieFile frameImageAtTime:time withAttributes:attributes error:NULL];
              
        if (theImage)
            theResult = [self movieFrameAsString:theImage];
        
        // Pass that filters the image, hopefully making it clearer to anaylze.
        if (theResult==NULL && theImage)
        {
            CIImage* image = [[CIImage alloc] initWithCGImage:theImage];
            theImage = [self ciFiltersPass:image];
            theResult = [self movieFrameAsString:theImage];
        }
                    
        if (theResult!=NULL || theImage==nil)
            exitNow=YES;
    }
    
    // Addition Scan for finding the Slate Clap, if the user chooses to.---------------------------------------------------------//
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipInpointIsAtSlateClap"] intValue] == 1 && theImage!=nil)
    {
        exitNow = NO;
        NSString* localResult = theResult;
        int localCounter = 0;  // Local Counter is used strictly to count 1 second beyond the current found frame.
        [movieFile setCurrentTime:time];
        QTTime oldTime;
        while (exitNow==NO)
        {
            time = [movieFile currentTime];
            theImage = (CGImageRef)[movieFile frameImageAtTime:time withAttributes:attributes error:NULL];            
            
            localResult = [self movieFrameAsString:theImage];
            
            // Pass that filters the image, hopefully making it clearer to anaylze.
/*            if (theResult==NULL)
            {
                CIImage* image = [[CIImage alloc] initWithCGImage:theImage];
                theImage = [self ciFiltersPass:image];
                theResult = [self movieFrameAsString:theImage];
            }*/

            
            if (QTTimeCompare(oldTime, time) == NSOrderedSame) // If we get to the last frame...
                exitNow = YES;

            else if (theImage == nil) // Exit if there is no image at all.
                exitNow = YES;

            else if (theImage != nil && localResult!=NULL)  // An image is found with a QR Code.
            {
                localCounter = 0;
                oldTime = [movieFile currentTime];
            }

            else if (localResult==NULL && localCounter < timebase) // An image is found but no QR Code
                localCounter++;
            
            else if (localResult==NULL && localCounter >= timebase) // Exits loop and increments the qrCodeMarker Count
                exitNow=YES;

            
            if (exitNow==YES) time = oldTime;
            else [movieFile stepForward];
        }
    }
    
    [movieFile setCurrentTime:time];
    [movieFile stepForward];
    time = [movieFile currentTime];
    
    // ***** THIS NEEDS TO BE CHANGED. This is the old qrCodeMarker. It used to count manually, now it gets the number off that god-awful equation.
    QTTimeConvert *returnSlateMark = [[QTTimeConvert alloc] initWithFPS:timebase timeValue:time.timeValue andTimeScale:time.timeScale];
    int slateMark = [returnSlateMark returnIntegerOfLocationUsingQTTime:time]; 
    [returnSlateMark release];
            
    NSNumber* localTotalDurationInFrames = [[NSNumber alloc] initWithInt:totalDurationInFrames];
    NSNumber* markerForSlate = [[NSNumber alloc] initWithInt:slateMark];
    NSNumber* localTimebase = [[NSNumber alloc] initWithInt:timebase];
    
    //Check to see if the result as 7 sections separated by "_"
    NSArray *lines=[theResult componentsSeparatedByString:@"_"];

    //Returns the result if there are 7 elements in the QRCode's Array.  It returns blank results if the QRCode is not found.
    if (lines.count == 7)
    {
        // All good.
    }
    
    else
        theResult = [[NSString alloc] initWithString:@"______"];
    
    // Creating a dictionary with all of the results from this method.
    NSArray* objects = [[NSArray alloc] initWithObjects:absoluteMoviePath, theResult, localTotalDurationInFrames, markerForSlate, localTimebase, fps, samples, videoTimeValue, videoTimeScale, audioTimeValue, audioTimeScale, timecodeStartInFrames, [NSNumber numberWithBool:timecodeIsDropFrame], nil];
    
    NSArray* keys = [[NSArray alloc] initWithObjects:@"absolutePath", @"codeResults", @"totalDurationInFrames", @"markerLocationInFrames", @"timebase", @"clipFPS", @"videoSampleCount", @"videoTimeValue", @"videoTimeScale", @"audioTimeValue", @"audioTimeScale", @"timecodeStartInFrames", @"timecodeIsDropFrame", nil];

    NSDictionary* qrScannerResults = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
    
    [localTotalDurationInFrames release];
    [markerForSlate release];
    [localTimebase release];
    [fps release];
    [samples release];
    [videoTimeScale release];
    [videoTimeValue release];
    [audioTimeScale release];
    [audioTimeValue release];
    [timecodeStartInFrames release];
    
    return qrScannerResults;  // Returns nothing for the codeResult, but allows the parser to get through it.          

    
}

//----------------------------------------------------------------------------------------------------------------------------------------
- (NSNumber*)frameRateOfMovie:(QTMovie*)mMovie
{
    double result = 0;
    
    for (QTTrack* track in [mMovie tracks])
    {
        QTMedia* trackMedia = [track media];
        
        if ([trackMedia hasCharacteristic:QTMediaCharacteristicHasVideoFrameRate])
        {
            QTTime mediaDuration = [(NSValue*)[trackMedia attributeForKey:QTMediaDurationAttribute] QTTimeValue];
            long mediaDurationScaleValue = mediaDuration.timeScale;
            long long mediaDurationTimeValue = mediaDuration.timeValue;
            long mediaSampleCount = [(NSNumber*)[trackMedia attributeForKey:QTMediaSampleCountAttribute] longValue];
            result = (double)mediaSampleCount * ((double)mediaDurationScaleValue / (double)mediaDurationTimeValue);
            break;
        }
    }
    
    NSNumber *resultNumber = [NSNumber numberWithDouble:result];
    
    return resultNumber;
}

#pragma mark - Image Processors
//----------------------------------------------------------------------------------------------------------------------------------------
- (CGImageRef)cgImageCreateFromCIImage:(CIImage *)ciImage
{
    NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithCIImage:ciImage];
    CGImageRef cgImage = rep.CGImage;
    [rep release];
    return cgImage;
}

//----------------------------------------------------------------------------------------------------------------------------------------
- (CGImageRef)nsImageToCGImageRef:(NSImage*)image
{
    NSData * imageData = [image TIFFRepresentation];
    CGImageRef imageRef;
    if(imageData)
    {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData,  NULL);
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    }
    return imageRef;
}

//----------------------------------------------------------------------------------------------------------------------------------------
- (void) saveAsPNG:(NSImage*)image withName:(NSString*)filename
{
    NSBitmapImageRep *bmpImageRep = [[NSBitmapImageRep alloc]initWithData:[image TIFFRepresentation]];
    [image addRepresentation:bmpImageRep];
    NSData *data = [bmpImageRep representationUsingType:NSPNGFileType     properties: nil];
    [bmpImageRep release];
    NSString* outputPath = [[NSString alloc] initWithFormat:@"/Users/augustanderson/Pictures/%@.png", filename];
    [data writeToFile:outputPath atomically: NO];
    [outputPath release];
}


//----------------------------------------------------------------------------------------------------------------------------------------
- (CGImageRef) ciFiltersPass:(CIImage*)image
{
    CIImage *resultImage = image;
    
    CIFilter *ciEffectFilter = [CIFilter filterWithName:@"CIColorControls"];
    [ciEffectFilter setDefaults];
    [ciEffectFilter setValue: resultImage forKey:@"inputImage"];
    [ciEffectFilter setValue:[NSNumber numberWithFloat: 0]   forKey:@"inputSaturation"];
    [ciEffectFilter setValue:[NSNumber numberWithFloat: .5]   forKey:@"inputBrightness"];
    [ciEffectFilter setValue:[NSNumber numberWithFloat: 4]   forKey:@"inputContrast"];
    resultImage = [ciEffectFilter valueForKey:@"outputImage"];
    
    CIFilter *ciSharpenFilter = [CIFilter filterWithName:@"CISharpenLuminance"];
    [ciSharpenFilter setDefaults];
    [ciSharpenFilter setValue: resultImage forKey:@"inputImage"];
    [ciSharpenFilter setValue:[NSNumber numberWithFloat: 2]   forKey:@"inputSharpness"];
    resultImage = [ciSharpenFilter valueForKey:@"outputImage"];
    
    return [self cgImageCreateFromCIImage:resultImage];
}

//----------------------------------------------------------------------------------------------------------------------------------------
- (BOOL) isDropFrame:(AVAssetTrack*)track
{
    BOOL result = NO;
    
    NSArray* description = [track formatDescriptions];
    NSEnumerator* descriptionEnum = [description objectEnumerator];
    CMFormatDescriptionRef nextDescription;
    
    while ((!result) && ((nextDescription = (CMFormatDescriptionRef)[descriptionEnum nextObject]) != nil)) {
        if (CMFormatDescriptionGetMediaType(nextDescription) == kCMMediaType_TimeCode) {
            uint32_t timeCodeFlags = CMTimeCodeFormatDescriptionGetTimeCodeFlags ((CMTimeCodeFormatDescriptionRef)nextDescription);
            result = ((timeCodeFlags & kCMTimeCodeFlag_DropFrame) != 0);
        }
    }
    
    return result;
}

//----------------------------------------------------------------------------------------------------------------------------------------
- (NSNumber*) returnTimecodeInFrames:(AVAssetTrack*)track avAsset:(AVAsset*)videoAsset
{
    NSNumber* timecodeStartInFrames;
    long timeStampFrame = 0;
    
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:videoAsset error:nil];
    AVAssetReaderTrackOutput *assetReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:nil];
    
    if ([assetReader canAddOutput:assetReaderOutput]) {
        [assetReader addOutput:assetReaderOutput];
        
        if ([assetReader startReading] == YES) {
            int count = 0;
            
            while ( [assetReader status]==AVAssetReaderStatusReading ) {
                CMSampleBufferRef sampleBuffer = [assetReaderOutput copyNextSampleBuffer];
                if (sampleBuffer == NULL) {
                    if ([assetReader status] == AVAssetReaderStatusFailed)
                        break;
                    else
                        continue;
                }
                count++;
                
                CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
                size_t length = CMBlockBufferGetDataLength(blockBuffer);
                
                if (length>0) {
                    unsigned char *buffer = (unsigned char*)malloc(length);
                    memset(buffer, 0, length);
                    CMBlockBufferCopyDataBytes(blockBuffer, 0, length, buffer);
                    
                    for (int i=0; i<length; i++) {
                        timeStampFrame = (timeStampFrame << 8) + buffer[i];
                    }
                    
                    free(buffer);
                }
                
                CFRelease(sampleBuffer);
            }
            
            if (count == 0)
                NSLog(@"No sample in the timecode track: %@", [assetReader error]);
            
            NSLog(@"Processed %d sample", count);
        }
    }
    
    if ([assetReader status] != AVAssetReaderStatusCompleted)
        [assetReader cancelReading];
    
    // If the number is over 2100000, then its probably just a bizarre, huge, useless number.
    if (timeStampFrame < 2100000)
        timecodeStartInFrames = [[NSNumber alloc] initWithFloat:timeStampFrame]; // Assign
    
    else
        timecodeStartInFrames = [[NSNumber alloc] initWithFloat:0]; // Assign
    
    return timecodeStartInFrames;
}

@end
