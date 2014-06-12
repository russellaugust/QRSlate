//
//  Revisions.h
//  QRSlate_Print
//
//  Created by August Anderson on 11/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@protocol RevisionDelegate

- (void) returnRevisionResults:(NSMutableDictionary*)dict;

@end


@interface Revisions : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
    id <RevisionDelegate> delegate;
    
    NSMutableDictionary *mainDict;  //Contains the movie paths and connections to slate file data, if there.
    NSMutableArray *mainQTArray;    
    NSMutableArray *unusedDataArray;  // Contains ONLY data that has no connection.
    NSMutableArray *usedDataArray;
    
    IBOutlet NSTableView *quicktimesList;
    IBOutlet NSTableView *unusedDataList;
    
    IBOutlet NSButton *nsButtonDisconnectData;
    IBOutlet NSButton *nsButtonSetClap;
    IBOutlet NSImageView *helpSetClap;
    
    IBOutlet NSTableColumn *quicktimeListQuicktimeFiles;
    IBOutlet NSTableColumn *quicktimeListDataConnects;
    
    IBOutlet QTMovieView *mMovieView;
    QTMovie *mMovie;
    
    IBOutlet NSTextField *textfieldActionInpoint;
    IBOutlet NSTextField *textfieldActionOutpoint;
    IBOutlet NSTextField *textfieldCameraRoll;
    IBOutlet NSTextField *textfieldCircleTake;
    IBOutlet NSTextField *textfieldFPS;
    IBOutlet NSTextField *textfieldIDNumber;
    IBOutlet NSTextField *textfieldIntExt;
    IBOutlet NSTextField *textfieldLensFilters;
    IBOutlet NSTextField *textfieldLocation;
    IBOutlet NSTextField *textfieldMOS;
    IBOutlet NSTextField *textfieldScene;
    IBOutlet NSTextField *textfieldSceneDuration;
    IBOutlet NSTextField *textfieldShotComment;
    IBOutlet NSTextField *textfieldShotDescription;
    IBOutlet NSTextField *textfieldShotType;
    IBOutlet NSTextField *textfieldSoundRoll;
    IBOutlet NSTextField *textfieldTake;
    IBOutlet NSTextField *textfieldTakeQuality;
    IBOutlet NSTextField *textfieldTimeofDay;
    IBOutlet NSTextField *textfieldFilename;
    IBOutlet NSTextField *textfieldSlateClap;    
    
}

@property (nonatomic, assign) id <RevisionDelegate> delegate;

- (IBAction)buttonSetClap:(id)sender;
- (IBAction)disconnectDataFromQT:(id)sender;
- (IBAction)buttonFinished:(id)sender;

- (void) deleteQTFieldAtRow:(NSInteger)selectedRow;
- (void) loadDataToRevision:(NSDictionary*)qrslateDict QuicktimesDictionary:(NSDictionary*)qtDict;
- (NSMutableDictionary*) linkDataToQuicktime:(NSMutableDictionary*)qtDict fromUnusedData:(NSMutableDictionary*)dataDict;
- (void) setDataSectionFields:(NSMutableDictionary*)dict;

@end
