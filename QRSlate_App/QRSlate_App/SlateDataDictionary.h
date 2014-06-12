//
//  slateDataDictionary.h
//  QRSlate_App
//
//  Created by August Anderson on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SlateDataDictionary : NSObject {
@private
    
    NSMutableDictionary* slateMasterDictionary;
    
}

- (void) inputDataIntoSlateDictionary:(NSDictionary*)dict;
- (void) displayDictionaryContentsForReference;
- (void) replaceDictionary:(NSMutableDictionary*)dict;
- (NSString*) returnDataFromSlateDictionary:(NSString*)theKey moviePath:(NSString*)absoluteMoviePath;
- (NSMutableDictionary*) returnClipDictionaryFromMasterDictionaryWithMoviePathKey:(NSString*)absoluteMoviePath;
- (NSMutableDictionary*) returnEntireDictionary;
- (void) updateDataWithSlateFile:(NSMutableDictionary*)dictionaryFromFile moviePath:(NSString*)absoluteMoviePath;
- (void) saveAsPlist;

@end
