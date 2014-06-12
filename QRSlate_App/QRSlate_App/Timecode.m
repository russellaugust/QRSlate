//
//  Timecode.m
//  QRSlate_iOS
//
//  Created by August Anderson on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Timecode.h"


@implementation Timecode

- (NSString*) getTimecodeTODWithCentiseconds
{
    // Create a date and time object.
    NSDate* date = [NSDate date];
    NSDateFormatter* formatterTimecode = [[[NSDateFormatter alloc] init]autorelease];
    [formatterTimecode setDateFormat:@"HH:mm:ss:SS"];
    NSString* timecode = [formatterTimecode stringFromDate:date];
    
    return timecode;
}

//------------------------------------------------------------------------------------------------------------------------------
- (NSString*) timecodeFromTODatFramerate:(int)framerate
{
    // Create a date and time object.
    NSDate* date = [NSDate date];
    NSDateFormatter* formatterTimecode = [[NSDateFormatter alloc] init];
    [formatterTimecode setDateFormat:@"HH:mm:ss"];
    NSDateFormatter* formatterMS = [[NSDateFormatter alloc] init];
    [formatterMS setDateFormat:@"SS"];
    NSString* clockTime = [formatterTimecode stringFromDate:date];
    NSString* millsecondsTime = [formatterMS stringFromDate:date];
    int millsecondsInt = [millsecondsTime intValue];
    float frames = floorf(((float)framerate * (float)millsecondsInt)/100);
    
    NSString* timecode = [[[NSString alloc] initWithFormat:@"%@:%02ld", clockTime, lroundf(frames)] autorelease];
    
    [formatterMS release];
    [formatterTimecode release];
    
    return timecode;
}

//------------------------------------------------------------------------------------------------------------------------------
- (NSString*) convertHHmmssSStoHHmmSSff:(NSString*)HHmmssSS withFramerate:(int)framerate
{
    
    NSArray* timeElements = [HHmmssSS componentsSeparatedByString:@":"];    
    int centisecondsInt = [[timeElements lastObject] intValue];
    float frames = floorf(((float)framerate * (float)centisecondsInt)/100);
    
    if (timeElements.count == 4)
    {
        NSString* timecode = [[[NSString alloc] initWithFormat:@"%@:%@:%@:%02ld",
                               [timeElements objectAtIndex:0], 
                               [timeElements objectAtIndex:1], 
                               [timeElements objectAtIndex:2], lroundf(frames)] autorelease];
        return timecode;
    }
    
    else
        return 0;
}

//------------------------------------------------------------------------------------------------------------------------------
- (NSString*) durationFromInpoint:(NSString*)inpoint toOutpoint:(NSString*)outpoint
{
    NSDateFormatter *df=[[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm:ss:SS"];

    NSDate *tc1 = [df dateFromString:inpoint];
    NSDate *tc2 = [df dateFromString:outpoint];
    NSDate *tcZero = [df dateFromString:@"00:00:00:00"];
    NSDate* durationTC = [tcZero dateByAddingTimeInterval:[tc2 timeIntervalSinceDate:tc1]];

    NSString* stringDuration = [[[NSString alloc] initWithString:[df stringFromDate:durationTC]] autorelease];
    
    [df release];
    
    return stringDuration;
}

//------------------------------------------------------------------------------------------------------------------------------
- (NSString*) convertFramesToTC:(int)totalFrames withFramerate:(int)fps
{    
    // Determine frames
    int seconds = floor(totalFrames/fps);
    int remainder = totalFrames-floor(totalFrames/fps)*fps;
    int frames = remainder;
    
    // Determines seconds from frames
    int minutes = floor(seconds/60);
    remainder = seconds-floor(seconds/60)*60;
    seconds = remainder;
    
    // Determines minutes from seconds
    int hours = floor(minutes/60);
    remainder = minutes-floor(minutes/60)*60;
    minutes = remainder;
    
    // Determine hours from minutes
    remainder = hours-floor(hours/60)*60;
    hours = remainder;
    
    hours = hours + 1;
    
    NSString *tcString = [[NSString alloc] initWithFormat:@"%02i:%02i:%02i:%02i", hours, minutes, seconds, frames];
    
    return tcString;
}

@end
