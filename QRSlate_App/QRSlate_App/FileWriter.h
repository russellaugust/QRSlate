//
//  FileWriter.h
//  QRSlate_App
//
//  Created by August Anderson on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FileWriter : NSObject {
@private
    
    NSString* filePath; 
    NSString* projectName;
    
    NSMutableArray* allTakesXML;
    
    NSString *allTakesALE;
    NSString *allTakesXMLFCPXClips;
    NSString *allTakesXMLFCPXAssets;    
    
}

- (void) writeFileLocation:(NSString*)theFilePath;
- (void) writeALEToFile;
- (void) writeXMLToFile:(NSString*)productionName;
- (void) writeXMLFCPXToFile:(NSString*)productionName;
- (void) addClipToXML:(NSDictionary *)clipInDictionary;
- (void) addClipToALE:(NSDictionary *)clipInDictionary;
- (void) addClipToXMLFCPX:(NSDictionary *)clipInDictionary clipReference:(int)idRef;
- (NSXMLElement*) createBinForXMLwithName:(NSString*)name;
- (NSXMLElement*) createMarker:(NSDictionary*)dict basedOnInpoint:(NSString*)takeInpoint andInPointInteger:(int)takeInpointInt withFramerate:(int)timebaseInt;

- (int) returnFramesFromTime:(NSString*)outTimeHHmmssSS atFramerate:(int)framerate;
- (NSString*) durationFromInpoint:(NSString*)inpoint toOutpoint:(NSString*)outpoint;

- (void)appendText:(NSString *)text toFile:(NSString *)localFilePath;

@end
