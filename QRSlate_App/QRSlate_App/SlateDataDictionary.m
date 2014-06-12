//
//  slateDataDictionary.m
//  QRSlate_App
//
//  Created by August Anderson on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SlateDataDictionary.h"

@implementation SlateDataDictionary 

- (id)init
{
    self = [super init];
    if (self) {
        
        slateMasterDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [slateMasterDictionary release];
    [super dealloc];
}

//---------------------------------------------------------------------------------------------------------------------------------
//THIS WILL STORE DATA IN slateMasterDictionary.  That is the master where the main stuff is.
- (void) inputDataIntoSlateDictionary:(NSDictionary*)dict
{
    // absoluteMoviePath - that is now in the dictionary
    NSString *stringFromQRCode = [[NSString alloc] initWithString:[dict objectForKey:@"codeResults"]];
    NSString *absoluteMoviePath = [[NSString alloc] initWithString:[dict objectForKey:@"absolutePath"]];

    // Separates data into an array for connecting to the keys.
    NSArray *lines= [[NSArray alloc] initWithArray:[stringFromQRCode componentsSeparatedByString:@"_"]]; 
    [stringFromQRCode release];

    // Initialize the required object
    NSArray *keys = [[NSArray alloc] 
                     initWithObjects:@"ID Number", @"Scene", @"Take", @"Camera Roll", 
                                     @"Sound Roll", @"Shot Type", @"Shot Description", nil];   
    
    NSMutableDictionary *dictionaryForClip = [[NSMutableDictionary alloc] initWithObjects:lines forKeys:keys];
    [keys release];
    [lines release];
    
    // This initializing the Keys in the individual clips so that there are no NIL entries.
    [dictionaryForClip setObject:@"" forKey:@"Int Ext"];
    [dictionaryForClip setObject:@"" forKey:@"Location"];
    [dictionaryForClip setObject:@"" forKey:@"MOS"];
    [dictionaryForClip setObject:@"" forKey:@"Time of Day"];
    [dictionaryForClip setObject:@"" forKey:@"Scene Duration"];
    [dictionaryForClip setObject:@"FALSE" forKey:@"Circle Take"];
    [dictionaryForClip setObject:@"" forKey:@"Take Quality"];
    [dictionaryForClip setObject:@"" forKey:@"Shot Comment"];
    [dictionaryForClip setObject:@"" forKey:@"Lens Filters"];
    [dictionaryForClip setObject:@"" forKey:@"FPS"];
    [dictionaryForClip setObject:@"" forKey:@"Action Inpoint"];
    [dictionaryForClip setObject:@"" forKey:@"Action Outpoint"];
    
    [dictionaryForClip setObject:[dict objectForKey:@"absolutePath"] forKey:@"File Path"];    
    [dictionaryForClip setObject:[dict objectForKey:@"totalDurationInFrames"] forKey:@"Clip Duration in Frames"];
    [dictionaryForClip setObject:[dict objectForKey:@"markerLocationInFrames"] forKey:@"Clip Slate Clap Location in Frames"];
    [dictionaryForClip setObject:[dict objectForKey:@"timebase"] forKey:@"Clip Timebase"];
    [dictionaryForClip setObject:[dict objectForKey:@"clipFPS"] forKey:@"Clip FPS"];    
    [dictionaryForClip setObject:[dict objectForKey:@"videoSampleCount"] forKey:@"Video Same Count"];
    [dictionaryForClip setObject:[dict objectForKey:@"videoTimeValue"] forKey:@"Video TimeValue"];
    [dictionaryForClip setObject:[dict objectForKey:@"videoTimeScale"] forKey:@"Video TimeScale"];
    [dictionaryForClip setObject:[dict objectForKey:@"audioTimeValue"] forKey:@"Audio TimeValue"];
    [dictionaryForClip setObject:[dict objectForKey:@"audioTimeScale"] forKey:@"Audio TimeScale"];

    [dictionaryForClip setObject:[dict objectForKey:@"timecodeStartInFrames"] forKey:@"Timecode Start In Frames"];
    [dictionaryForClip setObject:[dict objectForKey:@"timecodeIsDropFrame"] forKey:@"Timecode Is Drop Frame"];

    //Add the Dictionary for the single clip into the Master Dictionary, creating a 2D Dictionary
    [slateMasterDictionary setObject:dictionaryForClip forKey:absoluteMoviePath];
    [absoluteMoviePath release];
    [dictionaryForClip release];
}

//---------------------------------------------------------------------------------------------------------------------------------
- (void) displayDictionaryContentsForReference
{
    NSLog(@"------------------------MASTER DICTIONARY DATA----------------------");
    for (id key in slateMasterDictionary) 
    {
        NSLog(@"key: %@   value:%@", key, [slateMasterDictionary objectForKey:key]);
    }
    NSLog(@"------------------------MASTER DICTIONARY DATA----------------------");
}

//---------------------------------------------------------------------------------------------------------------------------------
- (NSString*) returnDataFromSlateDictionary:(NSString*)theKey moviePath:(NSString*)absoluteMoviePath
{
    NSString* dictionaryContent = [[slateMasterDictionary objectForKey:absoluteMoviePath] objectForKey:theKey];

    return dictionaryContent;
}

//---------------------------------------------------------------------------------------------------------------------------------
- (NSMutableDictionary*) returnClipDictionaryFromMasterDictionaryWithMoviePathKey:(NSString*)absoluteMoviePath
{
    NSMutableDictionary* dictionary = [slateMasterDictionary objectForKey:absoluteMoviePath];    
    return dictionary;
}

//---------------------------------------------------------------------------------------------------------------------------------
//Takes in the path to the PLIST data from the mobile QRSlate App and updates the Slate Data.  This is optional.
-(void) updateDataWithSlateFile:(NSMutableDictionary*)dictionaryFromFile moviePath:(NSString*)absoluteMoviePath
{    
    if (slateMasterDictionary != nil)
    {
        NSString *oldIDNumber = [[slateMasterDictionary objectForKey:absoluteMoviePath] objectForKey:@"ID Number"];
        
        BOOL hasMatched = NO;
        int i = 0;
        while (hasMatched == NO && i < [[dictionaryFromFile objectForKey:@"All Takes"] count])
        {
//            NSLog(@"Iteration %i of %i", i, (int)[[dictionaryFromFile objectForKey:@"All Takes"] count]);
            NSString *newIDNumber = [[NSString alloc] initWithString:
                                     [[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"ID Number"]];
            
            if ([oldIDNumber isEqualToString:newIDNumber])
            {
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Scene"] 
                 forKey:@"Scene"];

                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Take"] 
                 forKey:@"Take"];

                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Camera Roll"] 
                 forKey:@"Camera Roll"];

                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Sound Roll"] 
                 forKey:@"Sound Roll"];

                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Shot Type"] 
                 forKey:@"Shot Type"];
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Shot Description"] 
                 forKey:@"Shot Description"];

                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Int Ext"] 
                 forKey:@"Int Ext"];

                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Location"] 
                 forKey:@"Location"];

                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"MOS"] 
                 forKey:@"MOS"];
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Time of Day"] 
                 forKey:@"Time of Day"];
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Scene Duration"] 
                 forKey:@"Scene Duration"];
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Circle Take"] 
                 forKey:@"Circle Take"];
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Take Quality"] 
                 forKey:@"Take Quality"];
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Shot Comment"] 
                 forKey:@"Shot Comment"];
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Lens Filters"] 
                 forKey:@"Lens Filters"];                
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"FPS"] 
                 forKey:@"FPS"];                   
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Action Inpoint"] 
                 forKey:@"Action Inpoint"];   
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath]
                 setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Action Outpoint"] 
                 forKey:@"Action Outpoint"];
                
                // Checks to make sure there are markers in the file.  Users do not have to include markers.
                if ([[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Markers"] != nil)
                {
                    [[slateMasterDictionary objectForKey:absoluteMoviePath]
                     setObject:[[[dictionaryFromFile objectForKey:@"All Takes"] objectAtIndex:i] objectForKey:@"Markers"] 
                     forKey:@"Markers"];

                }
                
                hasMatched = YES;
                
                [[slateMasterDictionary objectForKey:absoluteMoviePath] setObject:@"YES" forKey:@"Updated with File"];
                
                [newIDNumber release];
            }
            
            else
            {
                [[slateMasterDictionary objectForKey:absoluteMoviePath] setObject:@"NO" forKey:@"Updated with File"];
            }
            
            i++;
        }
        
        [oldIDNumber release];
    }
    
    else
        NSLog(@"NO DATA in Master Dictionary.");
}

//----------------------------------------------------------------------------------------------------------------------------
-(void) saveAsPlist
{
    NSLog(@"This should be the SAVE LIST:  %@", slateMasterDictionary);
//    [slateMasterDictionary writeToFile:@"/Users/augustanderson/Desktop/qtfiles_withData.plist" atomically: YES];
}

//----------------------------------------------------------------------------------------------------------------------------
- (void) replaceDictionary:(NSMutableDictionary*)dict
{
    slateMasterDictionary = dict;
}

//----------------------------------------------------------------------------------------------------------------------------
- (NSMutableDictionary*) returnEntireDictionary
{
    return slateMasterDictionary;
}

@end


