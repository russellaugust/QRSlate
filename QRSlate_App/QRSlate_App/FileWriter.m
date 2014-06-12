//
//  FileWriter.m
//  QRSlate_App
//
//  Created by August Anderson on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileWriter.h"
#import "Timecode.h"
#import "QTTimeConvert.h"
#import "NSMutableString+XmlEscape.h"

@implementation FileWriter

- (id)init
{
    self = [super init];
    if (self) {
        
        allTakesXML = [[NSMutableArray alloc] init];
        allTakesALE = [[NSString alloc] init];
        allTakesXMLFCPXAssets = [[NSString alloc] init];
        allTakesXMLFCPXClips = [[NSString alloc] init];

    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
    
    [filePath release]; 
//    [projectName release];
    [allTakesXML release];
    [allTakesALE release];
    [allTakesXMLFCPXClips release];
    [allTakesXMLFCPXAssets release];    
}

//---------------------------------------------------------------------------------------------------------------------------------------------
// Sets the location of the file path where the XML File will be written.
- (void) writeFileLocation:(NSString*)theFilePath
{
    filePath = theFilePath;
}

//---------------------------------------------------------------------------------------------------------------------------------------------
- (void) writeALEToFile
{
    NSURL *url = [[NSURL alloc] initWithString:filePath];
    NSString *localFilePath = [[NSString alloc] initWithFormat:@"%@.ale", [url path]];

    NSString *videoFormat = [[NSUserDefaults standardUserDefaults] objectForKey: @"aleVideoFormat"];
    NSString *videoFramerate = [[NSUserDefaults standardUserDefaults] objectForKey: @"aleVideoFramerate"];
    NSString *audioFormat = [[NSUserDefaults standardUserDefaults] objectForKey: @"aleAudioFormat"];
    
    NSString *heading = [[NSString alloc] initWithFormat:@"Heading\nFIELD_DELIM\tTABS\nVIDEO_FORMAT\t%@\nAUDIO_FORMAT\t%@\nFPS\t%@\n\nColumn\n", 
                         videoFormat, audioFormat, videoFramerate];
    
    // Add file info to ALE.
    [self appendText:heading toFile:localFilePath];
    
    // Add HEADINGS to ALE.
    [self appendText:@"Name\tStart\tEnd\tMark IN\tMark OUT\tScene\tTake\tCamroll\tSoundroll\tTracks\tTape\tID Number\tIntExt\tLens\tMOS\tDescription\tComment\tShot Type\tQuality\tTime of Day\tSource File\n\nData\n"
              toFile:localFilePath];
    
    [self appendText:allTakesALE toFile:localFilePath];
    
    [url release];
    [localFilePath release];
    [heading release];

}
//---------------------------------------------------------------------------------------------------------------------------------------------
- (void) writeXMLToFile:(NSString*)productionName
{
    projectName = [[NSString alloc] initWithString:productionName];
    
    NSXMLElement *root = [[NSXMLElement alloc] initWithName:@"xmeml"];
    [root addAttribute:[NSXMLNode attributeWithName:@"version" stringValue:@"5"]];
    
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
    NSXMLDTD *myDTD = [[NSXMLDTD alloc] initWithKind:NSXMLDTDKind];
    [myDTD setName:@"xmeml"];
    [xmlDoc setDTD:myDTD];
    [xmlDoc setVersion:@"1.0"];
    [xmlDoc setCharacterEncoding:@"UTF-8"];
    
    NSXMLElement *projectRoot = [NSXMLElement elementWithName:@"project"]; 
    [root addChild:projectRoot]; 
    
    NSXMLElement *name = [[NSXMLElement alloc] initWithName:@"name"];
    [name setStringValue:projectName];
    [projectRoot addChild:name];
    [name release];
    
    NSXMLElement *projectChildren = [[NSXMLElement alloc] initWithName:@"children"];
    [projectRoot addChild:projectChildren];
    [projectChildren release];
    
    // Iterate through All Takes and add them to the project.
    for (NSXMLElement*s in allTakesXML)
    {   
        // If the user enables it with the Session Attributes, this will add each scene to its own bin.
        if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"useBins"] intValue] == 1)
        {
            NSArray* bins = [xmlDoc nodesForXPath:@"//bin" error:nil];
            
            NSXMLDocument* docElement = [[NSXMLDocument alloc] initWithRootElement:s];
            NSArray* scene = [docElement nodesForXPath:@"clip[1]/logginginfo[1]/scene[1]" error:nil];
            NSString* sceneName = [[scene objectAtIndex:0] stringValue]; // Creates a String for the Scene Number
            
            BOOL doesBinExist = NO;
            int x = 0;
            
            if (bins.count == 0)
            {
                [projectChildren addChild:[self createBinForXMLwithName:sceneName]];
                
                NSString* xpath = [[NSString alloc] initWithFormat:@"//bin[name = \"%@\"]/children", sceneName];
                NSArray *nodes = [xmlDoc nodesForXPath:xpath error:nil];
                NSXMLElement* binElement = [nodes objectAtIndex:0];
                
                [binElement addChild:[s copy]];
                [xpath release];
                doesBinExist = YES;
            }     
            
            while (doesBinExist == NO)
            {
                NSXMLDocument* docBin = [[NSXMLDocument alloc] initWithRootElement:[[bins objectAtIndex:x] copy]];
                NSArray* binNameArray = [docBin nodesForXPath:@"bin[1]/name[1]" error:nil];
                NSString* binName = [[binNameArray objectAtIndex:0] stringValue];
                
                if ([binName isEqualToString:sceneName])
                {
                    NSString* xpath = [[NSString alloc] initWithFormat:@"//bin[name = \"%@\"]/children", sceneName];
                    NSArray *nodes = [xmlDoc nodesForXPath:xpath error:nil];
                    NSXMLElement* binElement = [nodes objectAtIndex:0];
                    
                    [binElement addChild:[s copy]];
                    [xpath release];
                    doesBinExist = YES;
                }
                
                else if (doesBinExist == NO && x == bins.count-1)
                {
                    [projectChildren addChild:[self createBinForXMLwithName:sceneName]];
                    
                    NSString* xpath = [[NSString alloc] initWithFormat:@"//bin[name = \"%@\"]/children", sceneName];
                    NSArray *nodes = [xmlDoc nodesForXPath:xpath error:nil];
                    NSXMLElement* binElement = [nodes objectAtIndex:0];
                    
                    [binElement addChild:[s copy]];
                    [xpath release];
                    doesBinExist = YES;
                }
                
                x++;
                [docBin release];
            }
            
            [docElement release];
        }
        
        // If the users does not select this, then all of the clips will stay in the root bin.
        else
        {
            [projectChildren addChild:[s copy]];
        }
    }
    
    NSData *data = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
    NSString *appendedString = [[NSString alloc] initWithFormat:@"%@.xml", filePath];
    NSURL *xmlURLPath = [[NSURL alloc] initWithString:appendedString];
    [data writeToURL:xmlURLPath atomically:YES];
    
    [root release];
    [xmlDoc release];
    [appendedString release];
    [xmlURLPath release];
}

//---------------------------------------------------------------------------------------------------------------------------------------------
- (void) writeXMLFCPXToFile:(NSString*)productionName
{
    projectName = [[NSString alloc] initWithString:productionName];
    
    // Header
    NSMutableString *xmlHeader = [[NSMutableString alloc] initWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n"];
    [xmlHeader appendString:@"<!DOCTYPE fcpxml>\n"];
    [xmlHeader appendString:@"<fcpxml version=\"1.1\">\n"];
    [xmlHeader appendFormat:@"<project name=\"%@\">\n", projectName];
    
    // Resources
    NSMutableString *xmlResources = [[NSMutableString alloc] init];
    [xmlResources appendString:@"<resources>\n"];  
    [xmlResources appendFormat:@"<format id=\"r1\"/>\n"];
    
    // Assets
    [xmlResources appendString:allTakesXMLFCPXAssets];
    [xmlResources appendString:@"</resources>\n"];
    
    // Clips
    NSMutableString *xmlClip = [[NSMutableString alloc] init];
    [xmlClip appendString:allTakesXMLFCPXClips];
    
    // Footer
    NSMutableString *xmlFooter = [[NSMutableString alloc] init];
    [xmlFooter appendString:@"</project>\n"];
    [xmlFooter appendString:@"</fcpxml>\n"];
    

    NSURL *url = [[NSURL alloc] initWithString:filePath];
    NSString *localFilePath = [[NSString alloc] initWithFormat:@"%@.fcpxml", [url path]];
    
    // Add HEADING to XML.
    [self appendText:xmlHeader
              toFile:localFilePath];
    
    // Add RESOURCES to XML
    [self appendText:xmlResources 
              toFile:localFilePath];
    
    // Add CLIP to XML
    [self appendText:xmlClip 
              toFile:localFilePath];

    // Add FOOTER to XML.
    [self appendText:xmlFooter
              toFile:localFilePath];
    
    [xmlHeader release];
    [xmlResources release];
    [xmlClip release];
    [xmlFooter release];
    [url release];
    [localFilePath release];
    
}

//---------------------------------------------------------------------------------------------------------------------------------------------
- (void) addClipToXML:(NSDictionary *)clipInDictionary
{
    // Pull clip attributes int variables.
    NSString* absoluteMoviePath = [clipInDictionary objectForKey:@"File Path"];
    int clipDurationInFrames = [[clipInDictionary objectForKey:@"Clip Duration in Frames"] intValue];
    int timebaseInt = [[clipInDictionary objectForKey:@"Clip Timebase"] intValue];
    
    //Creates the filename as a string by removing the whole path.
    NSArray* separateFilename = [absoluteMoviePath componentsSeparatedByString:@"/"];
    //Creates the filename without extension.

    int inpointInt = [[clipInDictionary objectForKey:@"Clip Slate Clap Location in Frames"] intValue];
    int outpointInt = clipDurationInFrames;
    int actionDuration = [self returnFramesFromTime:[clipInDictionary objectForKey:@"Scene Duration"] atFramerate:timebaseInt];
    if (actionDuration > inpointInt)
        outpointInt = inpointInt + actionDuration;
    
    // Sets no OUT point if the users decides not to in the menu
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipInOutIsSceneDuration"] intValue] == 0) // Clears the OUTPOINT if the value is 0
        outpointInt = -1;

    // Sets if the clip name is the filename or Scene and Take
    NSString* clipName;
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipNameAsSceneTake"] intValue]== 1 &&
        [[clipInDictionary objectForKey:@"Scene"] isEqualTo:@""] &&
        [[clipInDictionary objectForKey:@"Take"] isEqualTo:@""])
        clipName = [[NSString alloc] initWithString:[separateFilename lastObject]];
    
    else if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipNameAsSceneTake"] intValue]== 1)
        clipName = [[NSString alloc] initWithFormat:@"%@_%@", [clipInDictionary objectForKey:@"Scene"], [clipInDictionary objectForKey:@"Take"]];
    else
        clipName = [[NSString alloc] initWithString:[separateFilename lastObject]];
    
    NSString* clipID = [[NSString alloc] initWithString:[separateFilename lastObject]];
    NSString* clipDuration = [[NSString alloc] initWithFormat:@"%i", clipDurationInFrames];
    NSString* clipTimebase = [[NSString alloc] initWithFormat:@"%i", timebaseInt]; // Need to figure out something new for this
    NSString* clipInpoint = [[NSString alloc] initWithFormat:@"%i", inpointInt];
    NSString* clipOutpoint = [[NSString alloc] initWithFormat:@"%i", outpointInt];
    NSString* clipDescription = [[NSString alloc] initWithString:[clipInDictionary objectForKey:@"Shot Description"]];
    NSString* clipScene = [[NSString alloc] initWithString:[clipInDictionary objectForKey:@"Scene"]];
    NSString* clipShottake = [[NSString alloc] initWithString:[clipInDictionary objectForKey:@"Take"]];
    NSString* clipGoodTake = [[NSString alloc] initWithString:[clipInDictionary objectForKey:@"Circle Take"]];
//    NSString* clipFile = [[NSString alloc] initWithString:[removedExtensionFromFilename objectAtIndex:0]];
    NSString* clipPathURL = [[NSString alloc] initWithString:
                             [absoluteMoviePath stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding]];
    NSString* clipDefaultAngle = [[NSString alloc] initWithString:[clipInDictionary objectForKey:@"Shot Type"]];
    NSString* clipMasterComment1 = [[NSString alloc] initWithString:[clipInDictionary objectForKey:@"Shot Comment"]];
    NSString* clipMasterComment2 = [[NSString alloc] initWithString:[clipInDictionary objectForKey:@"Lens Filters"]];
    NSString* clipMasterComment3 = [[NSString alloc] initWithFormat:@"MOS=%@  %@  TOD=%@", 
                                    [clipInDictionary objectForKey:@"MOS"],
                                    [clipInDictionary objectForKey:@"Int Ext"],
                                    [clipInDictionary objectForKey:@"Time of Day"]];
    NSString* clipMasterComment4 = [[NSString alloc] initWithString:[clipInDictionary objectForKey:@"Take Quality"]];
    NSString* clipClipCommentA = [[NSString alloc] initWithFormat:@"CAM ROLL %@", [clipInDictionary objectForKey:@"Camera Roll"]];
    NSString* clipClipCommentB = [[NSString alloc] initWithFormat:@"SND ROLL %@", [clipInDictionary objectForKey:@"Sound Roll"]];
    
    // Start adding CLIPS from here on.-///////////////////////////////////////////////////////////////////////////////////////
        
    NSString *file = [NSBundle pathForResource:@"clip" ofType:@"xml" inDirectory:[[NSBundle mainBundle] bundlePath]];
    
    NSError *err = nil;
    NSURL *furl = [NSURL fileURLWithPath:file];
    
    NSXMLDocument* doc = [[NSXMLDocument alloc] initWithContentsOfURL:furl 
                                                              options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA) 
                                                                error:&err];    
    for (int x=1; x<21; x++)
    {
        NSString *theXPath = [[NSString alloc] init];
        NSString *elementValue = [[NSString alloc] init];
        
        if (x==1)      { theXPath = [[NSString alloc] initWithString:@"clip[1]/name[1]"];
            elementValue = [[NSString alloc] initWithString:clipName];}        
        else if (x==2) { theXPath = [[NSString alloc] initWithString:@"clip[1]/duration[1]"];
            elementValue = [[NSString alloc] initWithString:clipDuration];}        
        else if (x==3) { theXPath = [[NSString alloc] initWithString:@"clip[1]/rate[1]/timebase[1]"];
            elementValue = [[NSString alloc] initWithString:clipTimebase];}        
        else if (x==4) { theXPath = [[NSString alloc] initWithString:@"clip[1]/in[1]"];
            elementValue = [[NSString alloc] initWithString:clipInpoint];}        
        else if (x==5) { theXPath = [[NSString alloc] initWithString:@"clip[1]/out[1]"];
            elementValue = [[NSString alloc] initWithString:clipOutpoint];}        
        
        else if (x==6) { theXPath = [[NSString alloc] initWithString:@"clip[1]/logginginfo[1]/description[1]"];
            elementValue = [[NSString alloc] initWithString:clipDescription];}
        else if (x==7) { theXPath = [[NSString alloc] initWithString:@"clip[1]/logginginfo[1]/scene[1]"];
            elementValue = [[NSString alloc] initWithString:clipScene];}
        else if (x==8) { theXPath = [[NSString alloc] initWithString:@"clip[1]/logginginfo[1]/lognote[1]"];
            elementValue = [[NSString alloc] initWithString:clipDefaultAngle];}
        else if (x==9) { theXPath = [[NSString alloc] initWithString:@"clip[1]/logginginfo[1]/shottake[1]"];
            elementValue = [[NSString alloc] initWithString:clipShottake];}
        else if (x==10) { theXPath = [[NSString alloc] initWithString:@"clip[1]/logginginfo[1]/good[1]"];
            elementValue = [[NSString alloc] initWithString:clipGoodTake];}
        
        else if (x==11) { theXPath = [[NSString alloc] initWithString:@"clip[1]/comments[1]/mastercomment1[1]"];
            elementValue = [[NSString alloc] initWithString:clipMasterComment1];}
        else if (x==12) { theXPath = [[NSString alloc] initWithString:@"clip[1]/comments[1]/mastercomment2[1]"];
            elementValue = [[NSString alloc] initWithString:clipMasterComment2];}
        else if (x==13) { theXPath = [[NSString alloc] initWithString:@"clip[1]/comments[1]/mastercomment3[1]"];
            elementValue = [[NSString alloc] initWithString:clipMasterComment3];}
        else if (x==14) { theXPath = [[NSString alloc] initWithString:@"clip[1]/comments[1]/mastercomment4[1]"];
            elementValue = [[NSString alloc] initWithString:clipMasterComment4];}
        else if (x==15) { theXPath = [[NSString alloc] initWithString:@"clip[1]/comments[1]/clipcommenta[1]"];
            elementValue = [[NSString alloc] initWithString:clipClipCommentA];}
        else if (x==16) { theXPath = [[NSString alloc] initWithString:@"clip[1]/comments[1]/clipcommentb[1]"];
            elementValue = [[NSString alloc] initWithString:clipClipCommentB];}
        
        else if (x==17) { theXPath = [[NSString alloc] initWithString:@"clip[1]/media[1]/video[1]/track[1]/clipitem[1]/name[1]"];
            elementValue = [[NSString alloc] initWithString:clipName];}
        else if (x==18) { theXPath = [[NSString alloc] initWithString:@"clip[1]/media[1]/video[1]/track[1]/clipitem[1]/file[1]/@id"];
            elementValue = [[NSString alloc] initWithString:clipID];}
        else if (x==19) { theXPath = [[NSString alloc] initWithString:@"clip[1]/media[1]/video[1]/track[1]/clipitem[1]/file[1]/name[1]"];
            elementValue = [[NSString alloc] initWithString:clipName];}
        else if (x==20) { theXPath = [[NSString alloc] initWithString:@"clip[1]/media[1]/video[1]/track[1]/clipitem[1]/file[1]/pathurl[1]"];
            elementValue = [[NSString alloc] initWithString:clipPathURL];}
        else if (x==21) { theXPath = [[NSString alloc] initWithString:@"clip[1]/defaultangle[1]"];
            elementValue = [[NSString alloc] initWithString:clipDefaultAngle];}
        
        NSError* err;
        NSArray* nodes = [doc nodesForXPath:theXPath error:&err];
        
        [theXPath release];
        [elementValue release];
        
        [[nodes objectAtIndex:0] setStringValue:elementValue];
        
    }
        
    // Adds the markers to the clip.  This is user selected.
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"useMarkers"] intValue]== 1)
    {
        for (int x=0; x<[[clipInDictionary objectForKey:@"Markers"] count]; x++)
        {
            NSXMLElement* marker = [self createMarker:[[clipInDictionary objectForKey:@"Markers"] objectAtIndex:x]  
                                       basedOnInpoint:[clipInDictionary objectForKey:@"Action Inpoint"] 
                                    andInPointInteger:inpointInt 
                                        withFramerate:timebaseInt];
            
            NSArray* rootNode = [doc nodesForXPath:@"clip[1]" error:&err];
            [[rootNode objectAtIndex:0] addChild:marker];
        }
    }
    
    //Adds the final created element to the main Element.
    NSXMLElement* element  = [[NSXMLElement alloc] initWithKind:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)];
    element = [[doc rootElement] copy];
    
    // Adds the final element to the Array.
    [allTakesXML addObject:element];
    
    [clipName release];
    [clipID release];
    [clipDuration release];
    [clipTimebase release];
    [clipInpoint release];
    [clipOutpoint release];
    [clipDescription release];
    [clipScene release];
    [clipShottake release];
    [clipGoodTake release];
    [clipPathURL release];
    [clipDefaultAngle release];
    [clipMasterComment1 release];
    [clipMasterComment2 release];
    [clipMasterComment3 release];
    [clipMasterComment4 release];
    [clipClipCommentA release];
    [clipClipCommentB release];
    [doc release];
    [element release];
}

//---------------------------------------------------------------------------------------------------------------------------------------------
- (void) addClipToALE:(NSDictionary *)dict
{
    // Loading the timecode math object.
    Timecode *tc = [[Timecode alloc] init];
    
    // Get full file path.
    NSString* absoluteMoviePath = [dict objectForKey:@"File Path"];
    NSString *absoluteMoviePathNoInitialSlash = [absoluteMoviePath substringFromIndex:1];
    
    // Pull clip attributes int variables.
    int clipDurationInFrames = [[dict objectForKey:@"Clip Duration in Frames"] intValue];
    int timebaseInt = [[dict objectForKey:@"Clip Timebase"] intValue];
    
    //Creates the filename as a string by removing the whole path.
    NSArray* separateFilename = [absoluteMoviePath componentsSeparatedByString:@"/"];
    //Creates the filename without extension.
    
    int inpointInt = [[dict objectForKey:@"Clip Slate Clap Location in Frames"] intValue];
    int outpointInt = clipDurationInFrames;
    int actionDuration = [self returnFramesFromTime:[dict objectForKey:@"Scene Duration"] atFramerate:timebaseInt];
    if (actionDuration > inpointInt)
        outpointInt = inpointInt + actionDuration;
    
    // Sets no IN or OUT point if the users decides not to in the menu
    NSString* actionInpoint;
    NSString* actionOutpoint;
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipInOutIsSceneDuration"] intValue] == 0)  // Clears Out Point if value is 0
    {
        actionInpoint = [[NSString alloc] initWithString:[tc convertFramesToTC:inpointInt withFramerate:timebaseInt]];;
        actionOutpoint = [[NSString alloc] initWithString:@""];
    }
    
    else // Uses In and Out Points if value is 1
    {
        actionInpoint = [[NSString alloc] initWithString:[tc convertFramesToTC:inpointInt withFramerate:timebaseInt]];
        actionOutpoint = [[NSString alloc] initWithString:[tc convertFramesToTC:outpointInt withFramerate:timebaseInt]];        
    }
    
    // Sets if the clip name is the filename or Scene and Take
    NSString* clipName;
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipNameAsSceneTake"] intValue]== 1 &&
        [[dict objectForKey:@"Scene"] isEqualTo:@""] &&
        [[dict objectForKey:@"Take"] isEqualTo:@""])
        clipName = [[NSString alloc] initWithString:[separateFilename lastObject]];
    
    else if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipNameAsSceneTake"] intValue]== 1)
        clipName = [[NSString alloc] initWithFormat:@"%@_%@", [dict objectForKey:@"Scene"], [dict objectForKey:@"Take"]];
    else
        clipName = [[NSString alloc] initWithString:[separateFilename lastObject]];
    
    
    
//    NSString* clipTimebase = [[NSString alloc] initWithFormat:@"%i", timebaseInt]; // Need to figure out something new for this
//    NSString* clipGoodTake = [[NSString alloc] initWithString:[dict objectForKey:@"Circle Take"]];
//    NSString* clipPathURL = [[NSString alloc] initWithString:
//                             [absoluteMoviePath stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding]];
    
    // Start adding CLIPS from here on.-///////////////////////////////////////////////////////////////////////////////////////
    
    NSString *name = [[NSString alloc] initWithString:clipName];
    NSString *start = [[NSString alloc] initWithString:@"01:00:00:00"];
    NSString *end = [[NSString alloc] initWithString:[tc convertFramesToTC:clipDurationInFrames withFramerate:timebaseInt]];
    NSString *markIn = [[NSString alloc] initWithString:actionInpoint];
    NSString *markOut = [[NSString alloc] initWithString:actionOutpoint];
    NSString *scene = [[NSString alloc] initWithString:[dict objectForKey:@"Scene"]];
    NSString *take = [[NSString alloc] initWithString:[dict objectForKey:@"Take"]];
    NSString *camRoll = [[NSString alloc] initWithString:[dict objectForKey:@"Camera Roll"]];
    NSString *soundRoll = [[NSString alloc] initWithString:[dict objectForKey:@"Sound Roll"]];
    NSString *tracks = [[NSString alloc] initWithString:@"VA1A2"];
    NSString *tape = [[NSString alloc] initWithString:@""];
    NSString *idNumber = [[NSString alloc] initWithString:[dict objectForKey:@"ID Number"]];
    NSString *intExt = [[NSString alloc] initWithString:[dict objectForKey:@"Int Ext"]];
    NSString *lensAndFilters = [[NSString alloc] initWithString:[dict objectForKey:@"Lens Filters"]];
    NSString *mos = [[NSString alloc] initWithString:[dict objectForKey:@"MOS"]];
    NSString *shotDescription = [[NSString alloc] initWithString:[dict objectForKey:@"Shot Description"]];
    NSString *shotComment = [[NSString alloc] initWithString:[dict objectForKey:@"Shot Comment"]];
    NSString *shotType = [[NSString alloc] initWithString:[dict objectForKey:@"Shot Type"]];
    NSString *quality = [[NSString alloc] initWithString:[dict objectForKey:@"Take Quality"]];
    NSString *tod = [[NSString alloc] initWithString:[dict objectForKey:@"Time of Day"]];
    NSString *sourceFile = [[NSString alloc] initWithString:absoluteMoviePathNoInitialSlash];
    
    NSString *clipContent = 
        [[NSString alloc] initWithFormat:@"%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\n", 
         name, start, end, markIn, markOut, scene, take, camRoll, soundRoll, tracks, tape, idNumber, intExt, 
         lensAndFilters, mos, shotDescription, shotComment, shotType, quality, tod, sourceFile];
    
    NSString *append = [[NSString alloc] initWithFormat:@"%@%@", allTakesALE, clipContent];
    
    allTakesALE = [[NSString alloc] initWithString:append];
    
    [append release];
    [clipContent release];
    [tc release];
    [actionInpoint release];
    [actionOutpoint release];
    [name release];
    [start release];
    [end release];
    [markIn release];
    [markOut release];
    [scene release];
    [take release];
    [camRoll release];
    [soundRoll release];
    [tracks release];
    [tape release];
    //[idNumber release];
    [intExt release];
    [lensAndFilters release];
    [mos release];
    [shotDescription release];
    [shotComment release];
    [shotType release];
    [quality release];
    [tod release];
    [sourceFile release];
    [clipName release];
}

//---------------------------------------------------------------------------------------------------------------------------------------------
- (void) addClipToXMLFCPX:(NSDictionary *)dict clipReference:(int)idRef
{
    NSString *absoluteMoviePath = [[NSString alloc] initWithString:[dict objectForKey:@"File Path"]];
    NSString *absoluteMoviePathPercentEscaped = [absoluteMoviePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSArray* separateFilename = [absoluteMoviePath componentsSeparatedByString:@"/"];
    NSString *fileName = [[NSString alloc] initWithString:[separateFilename lastObject]];
    
    //    NSString *videoSampleCount = [[NSString alloc] initWithString:[[dict objectForKey:@"Video Same Count"] stringValue]];
    NSMutableString *videoTimeValue = [[NSMutableString alloc] initWithString:[[dict objectForKey:@"Video TimeValue"] stringValue]];
    NSMutableString *videoTimeScale = [[NSMutableString alloc] initWithString:[[dict objectForKey:@"Video TimeScale"] stringValue]];
    NSMutableString *audioTimeValue = [[NSMutableString alloc] initWithString:[[dict objectForKey:@"Audio TimeValue"] stringValue]];
    NSMutableString *audioTimeScale = [[NSMutableString alloc] initWithString:[[dict objectForKey:@"Audio TimeScale"] stringValue]];
    NSNumber *timecodeStartInFrames = [dict objectForKey:@"Timecode Start In Frames"];
    [videoTimeValue xmlSimpleEscape];
    [videoTimeScale xmlSimpleEscape];
    [audioTimeValue xmlSimpleEscape];
    [audioTimeScale xmlSimpleEscape];
    
    NSMutableString *dfndf;
    if ([[dict objectForKey:@"Timecode Is Drop Frame"] intValue] == 1) dfndf = [[NSMutableString alloc] initWithString:@"DF"];
    else if ([[dict objectForKey:@"Timecode Is Drop Frame"] intValue] == 0) dfndf = [[NSMutableString alloc] initWithString:@"NDF"];
    [dfndf xmlSimpleEscape];
    
    NSMutableString *scene = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Scene"]];
    NSMutableString *take = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Take"]];
    NSMutableString *camRoll = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Camera Roll"]];
    NSMutableString *soundRoll = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Sound Roll"]];
    //    NSString *idNumber = [[NSString alloc] initWithString:[dict objectForKey:@"ID Number"]];
    NSMutableString *intExt = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Int Ext"]];
    NSMutableString *lensAndFilters = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Lens Filters"]];
    NSMutableString *mos = [[NSMutableString alloc] initWithString:[dict objectForKey:@"MOS"]];
    NSMutableString *shotDescription = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Shot Description"]];
    NSMutableString *shotComment = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Shot Comment"]];
    NSMutableString *shotType = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Shot Type"]];
    NSMutableString *quality = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Take Quality"]];
    NSMutableString *tod = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Time of Day"]];
    
    [scene xmlSimpleEscape];
    [take xmlSimpleEscape];
    [camRoll xmlSimpleEscape];
    [soundRoll xmlSimpleEscape];
    [intExt xmlSimpleEscape];
    [lensAndFilters xmlSimpleEscape];
    [mos xmlSimpleEscape];
    [shotDescription xmlSimpleEscape];
    [shotComment xmlSimpleEscape];
    [shotType xmlSimpleEscape];
    [quality xmlSimpleEscape];
    [tod xmlSimpleEscape];
    
    // If the Clip Name As Scene and Take is enabled, do it.
    NSMutableString *clipName;
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipNameAsSceneTake"] intValue] == 1)
    {
        // If the clip has no scene and take numbers, then name it after the filename.
        if (([[dict objectForKey:@"Scene"] isEqualTo:@""] || [[dict objectForKey:@"Scene"] isEqualTo:@" "]) &&
            [[dict objectForKey:@"Take"] isEqualTo:@""])
            clipName = [[NSMutableString alloc] initWithString:fileName];
        
        else
            clipName = [[NSMutableString alloc] initWithFormat:@"%@_%@", scene, take];
    }
    
    else
        clipName = [[NSMutableString alloc] initWithString:fileName];
    
    [clipName xmlSimpleEscape];
    
    // ASSETS
    // Note:  idRef is +2 to displace it from the 0 base, so its starting at 2, then 3, 4, 5, etc.  Since the first ref is 1, baked in.
    NSMutableString *xmlAssets = [[NSMutableString alloc] init];
    [xmlAssets appendFormat:@"<asset id=\"r%i\" name=\"%@\" src=\"file://localhost%@\"/>\n", idRef+2, fileName, absoluteMoviePathPercentEscaped];
    
    // CLIPS
    NSMutableString *xmlClip = [[NSMutableString alloc] init];
    [xmlClip appendFormat:@"<clip name=\"%@\" duration=\"%@/%@s\" format=\"r1\" tcFormat=\"%@\">\n", clipName, videoTimeValue, videoTimeScale, dfndf];
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipNameAsSceneTake"] intValue] == 0)
    {
        if (([[dict objectForKey:@"Scene"] isEqualTo:@""] || [[dict objectForKey:@"Scene"] isEqualTo:@" "]) &&
            [[dict objectForKey:@"Take"] isEqualTo:@""])
            [xmlClip appendFormat:@"<note>\n%@\n%@</note>\n", shotDescription, shotComment];
        else
            [xmlClip appendFormat:@"<note>%@_%@\n%@\n%@</note>\n", scene, take, shotDescription, shotComment];
    }
    else
        [xmlClip appendFormat:@"<note>%@\n%@</note>\n", shotDescription, shotComment];
    
    
    if ([timecodeStartInFrames intValue] != 0)
    {
        double newVideoTimeValue = ([timecodeStartInFrames doubleValue] * [[dict objectForKey:@"Video TimeScale"] doubleValue]) / [[dict objectForKey:@"Clip FPS"] doubleValue];
        [xmlClip appendFormat:@"<video offset=\"%.0lf/%@s\" ref=\"r%i\" duration=\"%@/%@s\" start=\"%.0lf/%@s\">\n",
         newVideoTimeValue, videoTimeScale, idRef+2, videoTimeValue, videoTimeScale, newVideoTimeValue, videoTimeScale];
        
        double newAudioTimeValue = ([timecodeStartInFrames doubleValue] * [[dict objectForKey:@"Audio TimeScale"] doubleValue]) / [[dict objectForKey:@"Clip FPS"] doubleValue];
        [xmlClip appendFormat:@"<audio lane=\"-1\" offset=\"%.0lf/%@s\" ref=\"r%i\" duration=\"%@/%@s\" start=\"%.0lf/%@s\"/>\n",
         newAudioTimeValue, audioTimeScale, idRef+2, audioTimeValue, audioTimeScale, newAudioTimeValue, audioTimeScale];
        
        [xmlClip appendString:@"</video>\n"];
    }
    
    else {
        [xmlClip appendFormat:@"<video ref=\"r%i\" duration=\"%@/%@s\">\n", idRef+2, videoTimeValue, videoTimeScale];
        [xmlClip appendFormat:@"<audio lane=\"-1\" ref=\"r%i\" duration=\"%@/%@s\"/>\n", idRef+2, audioTimeValue, audioTimeScale];
        [xmlClip appendString:@"</video>\n"];
    }
    
    // KEYWORDS
    
    if ([camRoll isEqualToString:@""] || [camRoll isEqualToString:@" "] || [camRoll isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Camera Roll: %@\"/>\n", videoTimeValue, videoTimeScale, camRoll];
    
    if ([soundRoll isEqualToString:@""] || [soundRoll isEqualToString:@" "] || [soundRoll isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Sound Roll: %@\"/>\n", videoTimeValue, videoTimeScale, soundRoll];
    
    if ([intExt isEqualToString:@""] || [intExt isEqualToString:@" "] || [intExt isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Location: %@\"/>\n", videoTimeValue, videoTimeScale, intExt];
    
    if ([lensAndFilters isEqualToString:@""] || [lensAndFilters isEqualToString:@" "] || [lensAndFilters isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Lens: %@\"/>\n", videoTimeValue, videoTimeScale, lensAndFilters];
    
    if ([mos isEqualToString:@""] || [mos isEqualToString:@" "] || [mos isEqualToString:nil] || [mos isEqualToString:@"FALSE"]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"MOS\"/>\n", videoTimeValue, videoTimeScale];
    
    if ([shotType isEqualToString:@""] || [shotType isEqualToString:@" "] || [shotType isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Camera Angle: %@\"/>\n", videoTimeValue, videoTimeScale, shotType];
    
    if ([quality isEqualToString:@""] || [quality isEqualToString:@" "] || [quality isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Take Quality: %@\"/>\n", videoTimeValue, videoTimeScale, quality];
    
    if ([tod isEqualToString:@""] || [tod isEqualToString:@" "] || [tod isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Time of Day: %@\"/>\n", videoTimeValue, videoTimeScale, tod];
    
    //if ([idNumber isEqualToString:@""] || [idNumber isEqualToString:@" "] || [idNumber isEqualToString:nil]) {}
    //else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Slate ID Number:  %@\"/>\n", videoTimeValue, videoTimeScale, idNumber];
    
    
    // There's probably some major redundancy here.  Clean it up, slice it down.
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipInOutIsSceneDuration"] intValue] == 1)
    {
        NSMutableString *takeInpoint = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Action Inpoint"]];
        NSMutableString *takeOutpoint = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Action Outpoint"]];
        [takeInpoint xmlSimpleEscape];
        [takeOutpoint xmlSimpleEscape];
        int timebaseInt = [[dict objectForKey:@"Clip Timebase"] intValue];
        int takeInpointInt = [[dict objectForKey:@"Clip Slate Clap Location in Frames"] intValue];
        
        NSString* durationFromInpointToOutpoint = [[NSString alloc] initWithString:[self durationFromInpoint:takeInpoint toOutpoint:takeOutpoint]];
        int durationFromInpointToOutpointInt = [self returnFramesFromTime:durationFromInpointToOutpoint atFramerate:timebaseInt];
        
        NSNumber *inpointNumber = [[NSNumber alloc] initWithInt:takeInpointInt];
        QTTimeConvert *convertInpoint = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                               sampleCount:[inpointNumber longValue]
                                                              andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
        
        NSNumber *inpointTimeValue = [[NSNumber alloc] initWithDouble:[convertInpoint returnTimevalue]];
        
        NSNumber *durationToOutpointNumber = [[NSNumber alloc] initWithInt:durationFromInpointToOutpointInt];
        QTTimeConvert *convertDurationToOutpoint = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                                          sampleCount:[durationToOutpointNumber longValue]
                                                                         andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
        
        NSNumber *durationToOutpointTimeValue = [[NSNumber alloc] initWithDouble:[convertDurationToOutpoint returnTimevalue]];
        
        
        [xmlClip appendFormat:@"<keyword start=\"%@/%@s\" duration=\"%@/%@s\" value=\"Action\"/>\n", inpointTimeValue, videoTimeScale, durationToOutpointTimeValue, videoTimeScale];
        
        [takeInpoint release];
        [takeOutpoint release];
        [durationFromInpointToOutpoint release];
        [inpointNumber release];
        [convertInpoint release];
        [inpointTimeValue release];
        [durationToOutpointNumber release];
        [convertDurationToOutpoint release];
        [durationToOutpointTimeValue release];
        
    }
    
    // MARKERS
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"useMarkers"] intValue] == 1)
    {
        for (int x=0; x<[[dict objectForKey:@"Markers"] count]; x++)
        {
            // Builds a cleaner, localized version of the Markers Dictionary stored in the Clip's Dictionary
            NSDictionary *markerDict = [[NSDictionary alloc] initWithDictionary:[[dict objectForKey:@"Markers"] objectAtIndex:x]];
            NSMutableString* stringName = [[NSMutableString alloc] initWithString:[markerDict objectForKey:@"Marker Name"]];
            NSMutableString* stringComment = [[NSMutableString alloc] initWithString:[markerDict objectForKey:@"Marker Description"]];
            NSMutableString* markerTime = [[NSMutableString alloc] initWithString:[markerDict objectForKey:@"Marker Time"]];
            [stringName xmlSimpleEscape];
            [stringComment xmlSimpleEscape];
            [markerTime xmlSimpleEscape];
            
            // These are used to build the relative point of the markers
            NSMutableString *takeInpoint = [[NSMutableString alloc] initWithString:[dict objectForKey:@"Action Inpoint"]];
            [takeInpoint xmlSimpleEscape];
            
            int timebaseInt = [[dict objectForKey:@"Clip Timebase"] intValue];
            int takeInpointInt = [[dict objectForKey:@"Clip Slate Clap Location in Frames"] intValue];
            
            NSString* durationFromInpointToMarker = [[NSString alloc] initWithString:[self durationFromInpoint:takeInpoint toOutpoint:markerTime]];
            int durationFromInpointToMarkerInt = [self returnFramesFromTime:durationFromInpointToMarker atFramerate:timebaseInt];
            // 7 is being subtracted in hopes of lining up the location better.  This may be a framerate issue.
            
            int stringInpointInt = durationFromInpointToMarkerInt + takeInpointInt - 7;
            NSNumber *markerInpointNumber = [[NSNumber alloc] initWithInt:stringInpointInt];
            
            QTTimeConvert *timeConvert = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                                sampleCount:[markerInpointNumber longValue]
                                                               andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
            
            NSNumber *markerTimeValue = [[NSNumber alloc] initWithDouble:[timeConvert returnTimevalue]];
            
            QTTimeConvert *timeConvertOneFrame = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                                        sampleCount:1
                                                                       andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
            
            NSNumber *markerTimeValueOneFrame = [[NSNumber alloc] initWithDouble:[timeConvertOneFrame returnTimevalue]];
            
            [xmlClip appendFormat:@"<marker start=\"%@/%@s\" duration=\"%@/%@s\" value=\"%@ - %@\"/>\n", markerTimeValue, videoTimeScale, markerTimeValueOneFrame, videoTimeScale, stringName, stringComment];
            
            [markerDict release];
            [stringName release];
            [stringComment release];
            [markerTime release];
            [takeInpoint release];
            [durationFromInpointToMarker release];
            [markerInpointNumber release];
            [timeConvert release];
            [markerTimeValue release];
            [timeConvertOneFrame release];
            [markerTimeValueOneFrame release];
        }
    }
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipInpointIsAtSlateClap"] intValue] == 1 &&
        [[[NSUserDefaults standardUserDefaults] objectForKey: @"clipInOutIsSceneDuration"] intValue] == 0)
    {
        int takeInpointInt = [[dict objectForKey:@"Clip Slate Clap Location in Frames"] intValue];
        NSNumber *inpointNumber = [[NSNumber alloc] initWithInt:takeInpointInt];
        QTTimeConvert *convertInpoint = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                               sampleCount:[inpointNumber longValue]
                                                              andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
        NSNumber *inpointTimeValue = [[NSNumber alloc] initWithDouble:[convertInpoint returnTimevalue]];
        
        QTTimeConvert *timeConvertOneFrame = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                                    sampleCount:1
                                                                   andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
        NSNumber *timeValueOneFrame = [[NSNumber alloc] initWithDouble:[timeConvertOneFrame returnTimevalue]];
        
        [xmlClip appendFormat:@"<marker start=\"%@/%@s\" duration=\"%@/%@s\" value=\"Slate Clap\"/>\n", inpointTimeValue, videoTimeScale, timeValueOneFrame, videoTimeScale];
        
        [inpointNumber release];
        [convertInpoint release];
        [inpointTimeValue release];
        [timeConvertOneFrame release];
        [timeValueOneFrame release];
    }
    
    // Close CLIP Tag
    [xmlClip appendString:@"</clip>\n"];
    
    // Add clips to global storage for FCPX XML.
    NSString *appendAsset = [[NSString alloc] initWithFormat:@"%@%@", allTakesXMLFCPXAssets, xmlAssets];
    NSString *appendClip = [[NSString alloc] initWithFormat:@"%@%@", allTakesXMLFCPXClips, xmlClip];
    allTakesXMLFCPXAssets = [[NSString alloc] initWithString:appendAsset];
    allTakesXMLFCPXClips = [[NSString alloc] initWithString:appendClip];
    
    [absoluteMoviePath release];
    [fileName release];
    [videoTimeValue release];
    [videoTimeScale release];
    [audioTimeValue release];
    [audioTimeScale release];
    [scene release];
    [take release];
    [camRoll release];
    [soundRoll release];
    [intExt release];
    [lensAndFilters release];
    [mos release];
    [shotDescription release];
    [shotComment release];
    [shotType release];
    [quality release];
    [tod release];
    [clipName release];
    [xmlAssets release];
    [xmlClip release];
    [appendAsset release];
    [appendClip release];
    
}

/*
- (void) addClipToXMLFCPX:(NSDictionary *)dict clipReference:(int)idRef
{
    NSString *absoluteMoviePath = [[NSString alloc] initWithString:[dict objectForKey:@"File Path"]];
    NSString *absoluteMoviePathPercentEscaped = [absoluteMoviePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSArray* separateFilename = [absoluteMoviePath componentsSeparatedByString:@"/"];
    NSString *fileName = [[NSString alloc] initWithString:[separateFilename lastObject]];
    
//    NSString *videoSampleCount = [[NSString alloc] initWithString:[[dict objectForKey:@"Video Same Count"] stringValue]];
    NSString *videoTimeValue = [[NSString alloc] initWithString:[[dict objectForKey:@"Video TimeValue"] stringValue]];
    NSString *videoTimeScale = [[NSString alloc] initWithString:[[dict objectForKey:@"Video TimeScale"] stringValue]];
    NSString *audioTimeValue = [[NSString alloc] initWithString:[[dict objectForKey:@"Audio TimeValue"] stringValue]];
    NSString *audioTimeScale = [[NSString alloc] initWithString:[[dict objectForKey:@"Audio TimeScale"] stringValue]];
    NSNumber *timecodeStartInFrames = [dict objectForKey:@"Timecode Start In Frames"];
    
    NSString *dfndf;
    if ([[dict objectForKey:@"Timecode Is Drop Frame"] intValue] == 1) dfndf = [[NSString alloc] initWithString:@"DF"];
    else if ([[dict objectForKey:@"Timecode Is Drop Frame"] intValue] == 0) dfndf = [[NSString alloc] initWithString:@"NDF"];

    NSString *scene = [[NSString alloc] initWithString:[dict objectForKey:@"Scene"]];
    NSString *take = [[NSString alloc] initWithString:[dict objectForKey:@"Take"]];
    NSString *camRoll = [[NSString alloc] initWithString:[dict objectForKey:@"Camera Roll"]];
    NSString *soundRoll = [[NSString alloc] initWithString:[dict objectForKey:@"Sound Roll"]];
//    NSString *idNumber = [[NSString alloc] initWithString:[dict objectForKey:@"ID Number"]];
    NSString *intExt = [[NSString alloc] initWithString:[dict objectForKey:@"Int Ext"]];
    NSString *lensAndFilters = [[NSString alloc] initWithString:[dict objectForKey:@"Lens Filters"]];
    NSString *mos = [[NSString alloc] initWithString:[dict objectForKey:@"MOS"]];
    NSString *shotDescription = [[NSString alloc] initWithString:[dict objectForKey:@"Shot Description"]];
    NSString *shotComment = [[NSString alloc] initWithString:[dict objectForKey:@"Shot Comment"]];
    NSString *shotType = [[NSString alloc] initWithString:[dict objectForKey:@"Shot Type"]];
    NSString *quality = [[NSString alloc] initWithString:[dict objectForKey:@"Take Quality"]];
    NSString *tod = [[NSString alloc] initWithString:[dict objectForKey:@"Time of Day"]];
    
    // If the Clip Name As Scene and Take is enabled, do it.
    NSString *clipName;
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipNameAsSceneTake"] intValue] == 1)
    {
        // If the clip has no scene and take numbers, then name it after the filename.
        if (([[dict objectForKey:@"Scene"] isEqualTo:@""] || [[dict objectForKey:@"Scene"] isEqualTo:@" "]) && 
            [[dict objectForKey:@"Take"] isEqualTo:@""])
            clipName = [[NSString alloc] initWithString:fileName];
        
        else
            clipName = [[NSString alloc] initWithFormat:@"%@_%@", scene, take];
    }
    
    else
        clipName = [[NSString alloc] initWithString:fileName];

    // ASSETS
    // Note:  idRef is +2 to displace it from the 0 base, so its starting at 2, then 3, 4, 5, etc.  Since the first ref is 1, baked in.
    NSMutableString *xmlAssets = [[NSMutableString alloc] init];
    [xmlAssets appendFormat:@"<asset id=\"r%i\" name=\"%@\" src=\"file://localhost%@\"/>\n", idRef+2, fileName, absoluteMoviePathPercentEscaped];
    
    // CLIPS
    NSMutableString *xmlClip = [[NSMutableString alloc] init];
    [xmlClip appendFormat:@"<clip name=\"%@\" duration=\"%@/%@s\" format=\"r1\" tcFormat=\"%@\">\n", clipName, videoTimeValue, videoTimeScale, dfndf];
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipNameAsSceneTake"] intValue] == 0)
    {
        if (([[dict objectForKey:@"Scene"] isEqualTo:@""] || [[dict objectForKey:@"Scene"] isEqualTo:@" "]) &&
            [[dict objectForKey:@"Take"] isEqualTo:@""])
            [xmlClip appendFormat:@"<note>\n%@\n%@</note>\n", shotDescription, shotComment];
        else
            [xmlClip appendFormat:@"<note>%@_%@\n%@\n%@</note>\n", scene, take, shotDescription, shotComment];
    }
    else
        [xmlClip appendFormat:@"<note>%@\n%@</note>\n", shotDescription, shotComment];
    
    
    if ([timecodeStartInFrames intValue] != 0) {
        double newVideoTimeValue = ([timecodeStartInFrames doubleValue] * [[dict objectForKey:@"Video TimeScale"] doubleValue]) / [[dict objectForKey:@"Clip FPS"] doubleValue];
        [xmlClip appendFormat:@"<video offset=\"%.0lf/%@s\" ref=\"r%i\" duration=\"%@/%@s\" start=\"%.0lf/%@s\">\n",
         newVideoTimeValue, videoTimeScale, idRef+2, videoTimeValue, videoTimeScale, newVideoTimeValue, videoTimeScale];
        
        double newAudioTimeValue = ([timecodeStartInFrames doubleValue] * [[dict objectForKey:@"Audio TimeScale"] doubleValue]) / [[dict objectForKey:@"Clip FPS"] doubleValue];
        [xmlClip appendFormat:@"<audio lane=\"-1\" offset=\"%.0lf/%@s\" ref=\"r%i\" duration=\"%@/%@s\" start=\"%.0lf/%@s\"/>\n",
         newAudioTimeValue, audioTimeScale, idRef+2, audioTimeValue, audioTimeScale, newAudioTimeValue, audioTimeScale];
        
        [xmlClip appendString:@"</video>\n"];
    }
    
    else {
        [xmlClip appendFormat:@"<video ref=\"r%i\" duration=\"%@/%@s\">\n", idRef+2, videoTimeValue, videoTimeScale];
        [xmlClip appendFormat:@"<audio lane=\"-1\" ref=\"r%i\" duration=\"%@/%@s\"/>\n", idRef+2, audioTimeValue, audioTimeScale];
        [xmlClip appendString:@"</video>\n"];
    }

    // KEYWORDS
    
    if ([camRoll isEqualToString:@""] || [camRoll isEqualToString:@" "] || [camRoll isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Camera Roll: %@\"/>\n", videoTimeValue, videoTimeScale, camRoll];

    if ([soundRoll isEqualToString:@""] || [soundRoll isEqualToString:@" "] || [soundRoll isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Sound Roll: %@\"/>\n", videoTimeValue, videoTimeScale, soundRoll];

    if ([intExt isEqualToString:@""] || [intExt isEqualToString:@" "] || [intExt isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Location: %@\"/>\n", videoTimeValue, videoTimeScale, intExt];
    
    if ([lensAndFilters isEqualToString:@""] || [lensAndFilters isEqualToString:@" "] || [lensAndFilters isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Lens: %@\"/>\n", videoTimeValue, videoTimeScale, lensAndFilters];
    
    if ([mos isEqualToString:@""] || [mos isEqualToString:@" "] || [mos isEqualToString:nil] || [mos isEqualToString:@"FALSE"]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"MOS\"/>\n", videoTimeValue, videoTimeScale];
    
    if ([shotType isEqualToString:@""] || [shotType isEqualToString:@" "] || [shotType isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Camera Angle: %@\"/>\n", videoTimeValue, videoTimeScale, shotType];
    
    if ([quality isEqualToString:@""] || [quality isEqualToString:@" "] || [quality isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Take Quality: %@\"/>\n", videoTimeValue, videoTimeScale, quality];
    
    if ([tod isEqualToString:@""] || [tod isEqualToString:@" "] || [tod isEqualToString:nil]) {}
    else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Time of Day: %@\"/>\n", videoTimeValue, videoTimeScale, tod];
 
    //if ([idNumber isEqualToString:@""] || [idNumber isEqualToString:@" "] || [idNumber isEqualToString:nil]) {}
     //else [xmlClip appendFormat:@"<keyword start=\"0s\" duration=\"%@/%@s\" value=\"Slate ID Number:  %@\"/>\n", videoTimeValue, videoTimeScale, idNumber];
    
    
    // There's probably some major redundancy here.  Clean it up, slice it down.
     if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipInOutIsSceneDuration"] intValue] == 1)
     {
         NSString *takeInpoint = [[NSString alloc] initWithString:[dict objectForKey:@"Action Inpoint"]];
         NSString *takeOutpoint = [[NSString alloc] initWithString:[dict objectForKey:@"Action Outpoint"]];
         int timebaseInt = [[dict objectForKey:@"Clip Timebase"] intValue];
         int takeInpointInt = [[dict objectForKey:@"Clip Slate Clap Location in Frames"] intValue];
         
         NSString* durationFromInpointToOutpoint = [[NSString alloc] initWithString:[self durationFromInpoint:takeInpoint toOutpoint:takeOutpoint]];
         int durationFromInpointToOutpointInt = [self returnFramesFromTime:durationFromInpointToOutpoint atFramerate:timebaseInt];
         
         NSNumber *inpointNumber = [[NSNumber alloc] initWithInt:takeInpointInt];
         QTTimeConvert *convertInpoint = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                                sampleCount:[inpointNumber longValue]
                                                               andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
         
         NSNumber *inpointTimeValue = [[NSNumber alloc] initWithDouble:[convertInpoint returnTimevalue]];
         
         NSNumber *durationToOutpointNumber = [[NSNumber alloc] initWithInt:durationFromInpointToOutpointInt];
         QTTimeConvert *convertDurationToOutpoint = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                                           sampleCount:[durationToOutpointNumber longValue]
                                                                          andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
         
         NSNumber *durationToOutpointTimeValue = [[NSNumber alloc] initWithDouble:[convertDurationToOutpoint returnTimevalue]];
         
         
         [xmlClip appendFormat:@"<keyword start=\"%@/%@s\" duration=\"%@/%@s\" value=\"Action\"/>\n", inpointTimeValue, videoTimeScale, durationToOutpointTimeValue, videoTimeScale];
         
         [takeInpoint release];
         [takeOutpoint release];
         [durationFromInpointToOutpoint release];
         [inpointNumber release];
         [convertInpoint release];
         [inpointTimeValue release];
         [durationToOutpointNumber release];
         [convertDurationToOutpoint release];
         [durationToOutpointTimeValue release];

     }

    // MARKERS
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"useMarkers"] intValue] == 1)
    {
        for (int x=0; x<[[dict objectForKey:@"Markers"] count]; x++)
        {
            // Builds a cleaner, localized version of the Markers Dictionary stored in the Clip's Dictionary
            NSDictionary *markerDict = [[NSDictionary alloc] initWithDictionary:[[dict objectForKey:@"Markers"] objectAtIndex:x]];
            NSString* stringName = [[NSString alloc] initWithString:[markerDict objectForKey:@"Marker Name"]];
            NSString* stringComment = [[NSString alloc] initWithString:[markerDict objectForKey:@"Marker Description"]];
            NSString* markerTime = [[NSString alloc] initWithString:[markerDict objectForKey:@"Marker Time"]];
            
            // These are used to build the relative point of the markers
            NSString *takeInpoint = [[NSString alloc] initWithString:[dict objectForKey:@"Action Inpoint"]];
            int timebaseInt = [[dict objectForKey:@"Clip Timebase"] intValue];
            int takeInpointInt = [[dict objectForKey:@"Clip Slate Clap Location in Frames"] intValue];
            
            NSString* durationFromInpointToMarker = [[NSString alloc] initWithString:[self durationFromInpoint:takeInpoint toOutpoint:markerTime]];
            int durationFromInpointToMarkerInt = [self returnFramesFromTime:durationFromInpointToMarker atFramerate:timebaseInt];
            // 7 is being subtracted in hopes of lining up the location better.  This may be a framerate issue.
            
            int stringInpointInt = durationFromInpointToMarkerInt + takeInpointInt - 7;
            NSNumber *markerInpointNumber = [[NSNumber alloc] initWithInt:stringInpointInt];
            
            QTTimeConvert *timeConvert = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                                sampleCount:[markerInpointNumber longValue]
                                                               andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
            
            NSNumber *markerTimeValue = [[NSNumber alloc] initWithDouble:[timeConvert returnTimevalue]];
            
            QTTimeConvert *timeConvertOneFrame = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                                        sampleCount:1
                                                                       andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
            
            NSNumber *markerTimeValueOneFrame = [[NSNumber alloc] initWithDouble:[timeConvertOneFrame returnTimevalue]];
            
            [xmlClip appendFormat:@"<marker start=\"%@/%@s\" duration=\"%@/%@s\" value=\"%@ - %@\"/>\n", markerTimeValue, videoTimeScale, markerTimeValueOneFrame, videoTimeScale, stringName, stringComment];
            
            [markerDict release];
            [stringName release];
            [stringComment release];
            [markerTime release];
            [takeInpoint release];
            [durationFromInpointToMarker release];
            [markerInpointNumber release];
            [timeConvert release];
            [markerTimeValue release];
            [timeConvertOneFrame release];
            [markerTimeValueOneFrame release];
        }
    }
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipInpointIsAtSlateClap"] intValue] == 1 &&
        [[[NSUserDefaults standardUserDefaults] objectForKey: @"clipInOutIsSceneDuration"] intValue] == 0)
    {
        int takeInpointInt = [[dict objectForKey:@"Clip Slate Clap Location in Frames"] intValue];
        NSNumber *inpointNumber = [[NSNumber alloc] initWithInt:takeInpointInt];
        QTTimeConvert *convertInpoint = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                               sampleCount:[inpointNumber longValue]
                                                              andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
        NSNumber *inpointTimeValue = [[NSNumber alloc] initWithDouble:[convertInpoint returnTimevalue]];
        
        QTTimeConvert *timeConvertOneFrame = [[QTTimeConvert alloc] initWithFPS:[[dict objectForKey:@"Clip FPS"] doubleValue]
                                                                    sampleCount:1
                                                                   andTimeScale:[[dict objectForKey:@"Video TimeScale"] longValue]];
        NSNumber *timeValueOneFrame = [[NSNumber alloc] initWithDouble:[timeConvertOneFrame returnTimevalue]];
        
        [xmlClip appendFormat:@"<marker start=\"%@/%@s\" duration=\"%@/%@s\" value=\"Slate Clap\"/>\n", inpointTimeValue, videoTimeScale, timeValueOneFrame, videoTimeScale];
        
        [inpointNumber release];
        [convertInpoint release];
        [inpointTimeValue release];
        [timeConvertOneFrame release];
        [timeValueOneFrame release];
    }

    // Close CLIP Tag
    [xmlClip appendString:@"</clip>\n"];
    
    // Add clips to global storage for FCPX XML.
    NSString *appendAsset = [[NSString alloc] initWithFormat:@"%@%@", allTakesXMLFCPXAssets, xmlAssets];
    NSString *appendClip = [[NSString alloc] initWithFormat:@"%@%@", allTakesXMLFCPXClips, xmlClip];
    allTakesXMLFCPXAssets = [[NSString alloc] initWithString:appendAsset];
    allTakesXMLFCPXClips = [[NSString alloc] initWithString:appendClip];
    
    [absoluteMoviePath release];
    [fileName release];
    [videoTimeValue release];
    [videoTimeScale release];
    [audioTimeValue release];
    [audioTimeScale release];
    [scene release];
    [take release];
    [camRoll release];
    [soundRoll release];
    [intExt release];
    [lensAndFilters release];
    [mos release];
    [shotDescription release];
    [shotComment release];
    [shotType release];
    [quality release];
    [tod release];
    [clipName release];
    [xmlAssets release];
    [xmlClip release];
    [appendAsset release];
    [appendClip release];
    
}
 */

//---------------------------------------------------------------------------------------------------------------------------------------------
- (NSXMLElement*) createBinForXMLwithName:(NSString*)name
{
    NSXMLElement *bin = [[[NSXMLElement alloc] initWithName:@"bin"] autorelease];
    
    NSXMLElement *binupdatebehavior = [[NSXMLElement alloc] initWithName:@"updatebehavior"];
    [binupdatebehavior setStringValue:@"add"];
    [bin addChild:binupdatebehavior];
    [binupdatebehavior release];    
    
    NSXMLElement *binname = [[NSXMLElement alloc] initWithName:@"name"];
    [binname setStringValue:name];
    [bin addChild:binname];
    [binname release];        
    
    NSXMLElement *binchildren = [[NSXMLElement alloc] initWithName:@"children"];
    [bin addChild:binchildren];
    [binchildren release];
    
    return bin;
}

//---------------------------------------------------------------------------------------------------------------------------------------------
- (NSXMLElement*) createMarker:(NSDictionary*)dict basedOnInpoint:(NSString*)takeInpoint andInPointInteger:(int)takeInpointInt withFramerate:(int)timebaseInt
{
    
    NSString* stringName = [[NSString alloc] initWithString:[dict objectForKey:@"Marker Name"]];
    NSString* stringComment = [[NSString alloc] initWithString:[dict objectForKey:@"Marker Description"]];    
    NSString* markerTime = [[NSString alloc] initWithString:[dict objectForKey:@"Marker Time"]];
    
    NSString* durationFromInpointToMarker = [[NSString alloc] initWithString:[self durationFromInpoint:takeInpoint toOutpoint:markerTime]];
    int durationFromInpointToMarkerInt = [self returnFramesFromTime:durationFromInpointToMarker atFramerate:timebaseInt];
    // 7 is being subtracted in hopes of lining up the location better.  This may be a framerate issue.
    int stringInpointInt = durationFromInpointToMarkerInt + takeInpointInt - 7;
    NSString* stringInpoint = [[NSString alloc] initWithFormat:@"%i", stringInpointInt];
    
    
    NSXMLElement *marker = [[[NSXMLElement alloc] initWithName:@"marker"] autorelease];
    
    NSXMLElement *name = [[NSXMLElement alloc] initWithName:@"name"];
    [name setStringValue:stringName];
    [marker addChild:name];
    [name release];    
    
    NSXMLElement *comment = [[NSXMLElement alloc] initWithName:@"comment"];
    [comment setStringValue:stringComment];
    [marker addChild:comment];
    [comment release];        
    
    NSXMLElement *color = [[NSXMLElement alloc] initWithName:@"color"];
    [marker addChild:color];
    [color release];
    
    NSXMLElement *colorAlpha = [[NSXMLElement alloc] initWithName:@"alpha"];
    [colorAlpha setStringValue:@"0"];
    [color addChild:colorAlpha];
    [colorAlpha release];
    
    NSXMLElement *colorRed = [[NSXMLElement alloc] initWithName:@"red"];
    [colorRed setStringValue:@"255"];
    [color addChild:colorRed];
    [colorRed release];
    
    NSXMLElement *colorGreen = [[NSXMLElement alloc] initWithName:@"green"];
    [colorGreen setStringValue:@"0"];
    [color addChild:colorGreen];
    [colorGreen release];
    
    NSXMLElement *colorBlue = [[NSXMLElement alloc] initWithName:@"blue"];
    [colorBlue setStringValue:@"0"];
    [color addChild:colorBlue];
    [colorBlue release];
    
    NSXMLElement *inpoint = [[NSXMLElement alloc] initWithName:@"in"];
    [inpoint setStringValue:stringInpoint];
    [marker addChild:inpoint];
    [inpoint release];
    
    NSXMLElement *outpoint = [[NSXMLElement alloc] initWithName:@"out"];
    [outpoint setStringValue:@"-1"];
    [marker addChild:outpoint];
    [outpoint release];
    
    [stringName release];
    [stringComment release];
    [markerTime release];
    [durationFromInpointToMarker release];
    [stringInpoint release];
    
    return marker;
}

//---------------------------------------------------------------------------------------------------------------------------------------------
- (int) returnFramesFromTime:(NSString*)outTimeHHmmssSS atFramerate:(int)framerate
{
    NSArray* timeElements = [outTimeHHmmssSS componentsSeparatedByString:@":"];
    int totalFrames = 0;
    
    if (timeElements.count == 4) // Checks to make sure that the string being inputted has a hh:mm:ss;SS format.
    {
        int centisecondsInt = [[timeElements objectAtIndex:3] intValue];
        float framesFloat = floorf(((float)framerate * (float)centisecondsInt)/100);
        
        int hours = [[timeElements objectAtIndex:0] intValue];
        int minutes = [[timeElements objectAtIndex:1] intValue];
        int seconds = [[timeElements objectAtIndex:2] intValue];
        int frames = lroundf(framesFloat);
        
        totalFrames = frames + (seconds*framerate) + (minutes*60*framerate) + (hours*60*60*framerate);
    }
        
    return totalFrames;
}

//---------------------------------------------------------------------------------------------------------------------------------------------
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

//---------------------------------------------------------------------------------------------------------------------------------------------
- (void)appendText:(NSString *)text toFile:(NSString *)localFilePath
{
    
    // NSFileHandle won't create the file for us, so we need to check to make sure it exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:localFilePath]) {
        
        // the file doesn't exist yet, so we can just write out the text using the 
        // NSString convenience method
        
        NSError *error = noErr;
        BOOL success = [text writeToFile:localFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (!success) {
            // handle the error
            NSLog(@"%@", error);
        }
        
    } 
    else {
        
        // the file already exists, so we should append the text to the end
        
        // get a handle to the file
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:localFilePath];
        
        // move to the end of the file
        [fileHandle seekToEndOfFile];
        
        // convert the string to an NSData object
        NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
        
        // write the data to the end of the file
        [fileHandle writeData:textData];
        
        // clean up
        [fileHandle closeFile];
    }
}

@end
