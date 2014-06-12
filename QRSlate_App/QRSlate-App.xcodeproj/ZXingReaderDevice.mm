//
//  ZXingReaderDevice.m
//  QRSlate_App
//
//  Created by August Anderson on 6/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ZXingReaderDevice.h"
#import "QRSlate_AppAppDelegate.h"
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

#import <QTKit/QTKit.h>
#import <QuartzCore/QuartzCore.h>


@implementation ZXingReaderDevice

@synthesize totalDurationInFrames;
@synthesize qrcodeMarker;
@synthesize timebase;

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
        // NSLog(@"started decode");
        ZXResult* results = [qrcodereader decode:binarybitmapInput hints:decodehints];
        // NSLog(@"finished decode");
                
        [luminancesource release];
        [binarizerInput release];
        [binarybitmapInput release];
        [decodehints release];
        [qrcodereader release];
                
        return [results text];
    }
    
    @catch (ZXReaderException* rex)
    {
        //NSLog(@"failed to decode, caught ReaderException '%@'", rex.reason);
        if (![rex.reason isEqualToString:@"Could not find three finder patterns"]) 
        {
            //NSLog(@"failed to decode, caught ReaderException '%@'", rex.reason);
        }
    } 
    
    @catch (ZXIllegalArgumentException* iex) 
    {
        NSLog(@"failed to decode, caught IllegalArgumentException '%@'", iex.reason);
    }
    
    @catch (id ue) 
    {
        NSLog(@"Caught unknown exception: %@", ue);
    }
        
    return 0;
}

//------------------------------------------------------------------------------------------------------------------------
// Inputs a QUICKTIME, processes the image with filters, runs it through ZXing, and returns the result as an NSString
- (NSString*) quicktimeProcessorAndScanner:(NSString*)absoluteMoviePath qualityLevelOneThruThree:(int)qualityLevel sessionAttributes:(NSDictionary*)sessAttrib
{
    
    QTMovie *movieFile = [QTMovie movieWithFile:absoluteMoviePath error:NULL];

    NSArray *tracks = [movieFile tracks];
    NSString* timeIncrementString = [[NSString alloc] init];

    for(QTTrack *track in tracks)
    {
        QTMedia *media = [track media];
//        NSLog(@"In the for, also %@ and %@", [media attributeForKey:QTMediaTypeAttribute], QTMediaTypeVideo);  
        
        // Checks to make sure the quicktime media being inputted has a video track.
        if([[media attributeForKey:QTMediaTypeAttribute] isEqualToString:QTMediaTypeVideo])
        {
            NSNumber *samples = [media attributeForKey:QTMediaSampleCountAttribute];
//            NSLog(@"Total Frames Samples: %ld", (NSInteger)[samples integerValue]);
            
            // Returns the total number of frames.
            totalDurationInFrames = (NSInteger)[samples integerValue];
            
            NSNumber *timescale = [media attributeForKey:QTMediaTimeScaleAttribute];
            NSLog(@"Frame Rate Timescale: %ld", (NSInteger)[timescale integerValue]);

            // Sets the Time Increment using the timescale.
            timeIncrementString = [[NSString alloc] initWithFormat:@"00:00:00:01.0000/%ld", (NSInteger)[timescale integerValue]];            

            NSValue *duration = [media attributeForKey:QTMediaDurationAttribute];
            QTTime dur = [duration QTTimeValue];

            // Returns the framerate as a timebase.
            timebase = [self createFormattedTimebaseFromQTAttribute:timescale];
        }
    }
    
    NSValue *qtDimension = [movieFile attributeForKey:QTMovieNaturalSizeAttribute];
    NSSize qtDimensionNSSize = [qtDimension sizeValue];
    
    // Sets the dimensions on the file being analyzed based on user input.
    int divider;
    if (qualityLevel == 2)
        divider = 4;
    else if (qualityLevel == 1)
        divider = 2;
    else if (qualityLevel == 0)
        divider = 1;
    
    float x = qtDimensionNSSize.width / divider;
    float y = qtDimensionNSSize.height / divider;
    
    NSSize qtResizeDimensionNSSize = NSMakeSize(x, y);
    NSValue *qtResizeDimension = [NSValue valueWithSize:qtResizeDimensionNSSize];
    NSLog(@"Dimensions: %@", qtResizeDimension);  
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:qtResizeDimension forKey:QTMovieFrameImageSize];
    
    QTTime timeIncrementer = QTTimeFromString(timeIncrementString);
    [timeIncrementString release];
    QTTime time = [movieFile currentTime];
    
    BOOL exitNow = NO;
    NSString *theResult = NULL;
    
    NSImage *theImage = (NSImage*)[movieFile frameImageAtTime:time
                                               withAttributes:attributes 
                                                        error:NULL];
    
    NSBitmapImageRep *bmpImageRep = [[NSBitmapImageRep alloc] initWithData:[theImage TIFFRepresentation]];
    CIImage* ciImageFromcgImage = [[CIImage alloc] initWithBitmapImageRep:bmpImageRep];
    CGImageRef filteredcgImage = [self ciFiltersPass:ciImageFromcgImage];

    qrcodeMarker = 0;
    
    //Scans through QT Frames incrementing by timeIncrementer
    while (exitNow==NO)
    {
        theImage = (NSImage*)[movieFile frameImageAtTime:time
                                          withAttributes:attributes 
                                                   error:NULL];

        if (theImage != nil && theResult==NULL)
        {
            //NSLog(@"Current Time:  %@", QTStringFromTime(time));
            bmpImageRep = [bmpImageRep initWithData:[theImage TIFFRepresentation]];
            ciImageFromcgImage = [ciImageFromcgImage initWithBitmapImageRep:bmpImageRep];
            filteredcgImage = [self ciFiltersPass:ciImageFromcgImage];
            
            theResult = [self movieFrameAsString:filteredcgImage];
            
            time = QTTimeIncrement(time, timeIncrementer);
            qrcodeMarker++;
        }
        
        else
            exitNow=YES;
    }
    
    qrcodeMarker = qrcodeMarker * timebase;
    NSLog(@"qrcodeMarker A:  %i", qrcodeMarker);

    NSLog(@"clipinpointisatslateclap:  %@", sessAttrib);
    if ([[sessAttrib objectForKey:@"clipInpointIsAtSlateClap"] intValue] == 1)
    {
        
        // Does an additional Analysis if the user wants to set it to return the clap stick
        exitNow = NO;
        NSString *noResult = theResult;
        [movieFile setCurrentTime:time];
        
        while (exitNow==NO)
        {
            time = [movieFile currentTime];
            //        NSLog(@"Current Time:  %@", time);
            theImage = (NSImage*)[movieFile frameImageAtTime:time
                                              withAttributes:attributes 
                                                       error:NULL];
            
            if (theImage != nil && noResult!=NULL)
            {
                bmpImageRep = [bmpImageRep initWithData:[theImage TIFFRepresentation]];
                ciImageFromcgImage = [ciImageFromcgImage initWithBitmapImageRep:bmpImageRep];
                filteredcgImage = [self ciFiltersPass:ciImageFromcgImage];
                
                noResult = [self movieFrameAsString:filteredcgImage];
                NSLog(@"Current Result:  %@", [self movieFrameAsString:filteredcgImage]);
                
                [movieFile stepForward];
                qrcodeMarker++;
                
            }
            
            else
                exitNow=YES;
        }
        
        NSLog(@"qrcodeMarker B:  %i", qrcodeMarker);
    }
        
    [bmpImageRep release];
    [ciImageFromcgImage release];
    
    //Check to see if the result as 7 sections separated by "_"
    NSArray *lines=[theResult componentsSeparatedByString:@"_"];
    //Returns the result if there are 7 elements in the QRCode's Array.  It returns blank results if the QRCode is not found.
    if (lines.count == 7)
        return theResult;
    else
    {
        qrcodeMarker = 0; // Reset the Marker for where the QRCode is back to 0, because there is no code.
        return @"______"; // Returns nothing, but allows the parser to get through it.  
    }
    
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
- (void) saveAsPNG:(NSImage*)theInput
{
    NSBitmapImageRep *bmpImageRep = [[NSBitmapImageRep alloc]initWithData:[theInput TIFFRepresentation]];
    [theInput addRepresentation:bmpImageRep];
    NSData *data = [bmpImageRep representationUsingType:NSPNGFileType     properties: nil];
    [bmpImageRep release];
    [data writeToFile:[NSString stringWithFormat:@"/Users/august/Pictures/outputImage.png"]    atomically: NO];
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
- (int) createFormattedTimebaseFromQTAttribute:(NSNumber*)qtmediatimescaleattribute
{
    int timescale = [qtmediatimescaleattribute integerValue];
    int framerate;

    if (timescale == 23976 || timescale == 24)
        framerate = 24;

    else if (timescale == 2997 || timescale == 3000 || timescale == 30000 || timescale == 9000 || timescale == 90000)
        framerate = 30;

    else if (timescale == 2500)
        framerate = 25;
    
    else if (timescale == 1500)
        framerate = 15;
    
    return framerate;
}

@end
