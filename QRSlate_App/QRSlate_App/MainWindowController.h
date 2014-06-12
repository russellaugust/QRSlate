//
//  TableViewController.h
//  QRSlate_App
//
//  Created by August Anderson on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "Revisions.h"

@interface MainWindowController : NSWindowController <RevisionDelegate> {
@private

    NSTableView         *tableView;
    NSArrayController   *arrayController;
    
    NSMutableArray   *qrStringSets;  // An Array filled with dictionaries containing:  
                                     // "absolutePath", "codeResults", "totalDurationInFrames", "markerLocationInFrames", "timebase"
    
    NSMutableArray      *absoluteMoviePaths;
    NSString            *fileLocationPath;
    NSString            *plistFileLocation;
    NSMutableDictionary *plistDictionary;
    NSMutableDictionary *revisedDictionary;
    
    IBOutlet NSTextField *plistFileLocationView;
    IBOutlet NSProgressIndicator *analyzeMediaProgress;
    IBOutlet NSButton    *runButton;
    IBOutlet NSButton    *plistImportButton;
    IBOutlet NSButton    *printDataButton;
    IBOutlet NSButton    *clearCurrentSessionButton;
    
    IBOutlet NSPopUpButton    *selectQuality;
    IBOutlet NSButton *setInToOut;
    IBOutlet NSButton *setInAsSlateClap;    
    IBOutlet NSButton *setClipNameToSceneAndTake;
    IBOutlet NSButton *setBinsEnabled;
    IBOutlet NSButton *setSequencesEnabled;
    IBOutlet NSButton *setMarkersEnabled;
    
    IBOutlet NSButton *setExportXMLFCP7;
    IBOutlet NSButton *setExportXMLFCPX;
    IBOutlet NSButton *setExportXMLPremiere;

    IBOutlet NSButton *setExportALE;
    IBOutlet NSMatrix *setALEVideoFormat;
    IBOutlet NSMatrix *setALEVideoFramerate;
    IBOutlet NSMatrix *setALEAudioFormat;
    
    IBOutlet NSView   *view;
    
    NSOperationQueue *operationQueue;
    
}

@property (assign) IBOutlet NSTableView* tableView;
@property (assign) IBOutlet NSArrayController* arrayController;

- (IBAction)anaylzeMediaButton: (id) sender;
- (IBAction) openSlateFileForUpdater: (id) sender;
- (IBAction) clearCurrentSession: (id) sender;
- (IBAction)printDataAction: (id) sender;
- (IBAction)importClipsButton: (id)sender;

- (IBAction)demoButton: (id) sender;

- (void)saveDialogForEditorialFile;
- (void) scanForQRCodesWithAbsolutePath:(NSString*)absoluteMoviePath;
- (void) prepareMediaForExportToNLE;
- (void) shouldButtonsBeEnabled:(BOOL)boolValue;
- (void) loadSessionUserInputIntoDictionary;
- (void) clearSession;
- (void) deleteTableRows;
- (void) importMediaFiles:(NSArray*)files;
- (void) alertFinishedImport;

@end
