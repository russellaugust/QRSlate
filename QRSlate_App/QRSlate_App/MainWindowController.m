//
//  TableViewController.m
//  QRSlate_App
//
//  Created by August Anderson on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainWindowController.h"

#import <QTKit/QTKit.h>

#import "QRSlate_AppAppDelegate.h"
#import "ZXingReaderDevice.h"
#import <QuartzCore/QuartzCore.h>
#import "SlateDataDictionary.h"
#import "FileWriter.h"

#import "Revisions.h"
#import "Print.h"


@implementation MainWindowController

@synthesize tableView;
@synthesize arrayController;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        qrStringSets = [[NSMutableArray alloc] init];
        [qrStringSets retain];
        operationQueue = [[NSOperationQueue alloc] init];
        plistFileLocation = [[NSString alloc] initWithString:@""];
}
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
    
    [qrStringSets release];
    [absoluteMoviePaths release];
    [fileLocationPath release];
    [plistFileLocation release];
    [plistDictionary release];
    [revisedDictionary release];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Sets up the dragging system to work.
    [tableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [tableView reloadData];
    [tableView deselectAll:nil];
    
    ////////////////////////////////////////////////////////////////////////////////
    // Something needs to be here that will check if this is the first run or not.  Google Search FIRST RUN
    ////////////////////////////////////////////////////////////////////////////////    
}

#pragma mark - TableView delegates
//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL) tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard
{
    return YES;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    return NSDragOperationEvery;
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pboard = [info draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) 
    {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        [self importMediaFiles:files];
    }
        
    return YES;
}

//---------------------------------------------------------------------------------------------------------------------------
// Used to Sort the Column.
-(void)tableView:(NSTableView *)tv sortDescriptorsDidChange: (NSArray *)oldDescriptors 
{       
    NSArray *newDescriptors = [tv sortDescriptors];
    [[arrayController mutableArrayValueForKey:@"content"] sortUsingDescriptors:newDescriptors]; 
    [tv reloadData];
}

#pragma mark - Buttons
//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction) openSlateFileForUpdater: (id) sender
{
    // Load .qrslate File
    NSURL *plistURLLocation;
    NSOpenPanel *openDlg = [NSOpenPanel openPanel]; 
    
    NSArray* extensions = [[NSArray alloc] initWithObjects:@"qrslate", nil];
    
    [openDlg setAllowedFileTypes:extensions];
    [openDlg setExtensionHidden:NO];
    [openDlg setCanCreateDirectories:YES];
    
    
    int result = (int)[openDlg runModal]; 
    
    if (result == NSOKButton)
    { 
        plistURLLocation = [openDlg URL];
        plistFileLocation = [plistURLLocation absoluteString];
        NSArray *array = [[plistURLLocation path] componentsSeparatedByString:@"/"];
        [plistFileLocationView setStringValue:[array lastObject]];
        
        [printDataButton setEnabled:YES];
        
        plistDictionary = [[NSMutableDictionary alloc] initWithContentsOfURL:plistURLLocation];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction) clearCurrentSession: (id) sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Clear current session?"];
    [alert setInformativeText:@"This will reset the window."];
    [alert setAlertStyle:NSCriticalAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


// Alert for the CLEAR Button
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo 
{
    if (returnCode == NSAlertFirstButtonReturn) 
        [self clearSession];
    
    [[NSApplication sharedApplication] stopModal];
}

// Resets the window, clears all user settings and video files.
- (void) clearSession
{
    [[arrayController mutableArrayValueForKey:@"content"] removeAllObjects];
    [plistDictionary removeAllObjects];

    [qrStringSets removeAllObjects];
//    qrStringSets = NULL;
    
    [revisedDictionary removeAllObjects];
//    revisedDictionary = NULL;
    
    [absoluteMoviePaths removeAllObjects];
    absoluteMoviePaths = NULL;
    
    fileLocationPath = NULL;
//    plistFileLocation = NULL;
    
    [plistFileLocationView setStringValue:@""];

}

//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction) toggleButtons: (id) sender
{
    NSButton* button = sender;
        
    if (button == setInAsSlateClap)
    {
        [setInToOut setEnabled:button.state];
        [setMarkersEnabled setEnabled:button.state];
    }
    
    if (button == setExportALE)
    {
        [setALEAudioFormat setEnabled:button.state];
        [setALEVideoFormat setEnabled:button.state];
        [setALEVideoFramerate setEnabled:button.state];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction)demoButton: (id) sender
{
    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"Hello" forKey: @"Testing"]; // The forKey is the name of the setting you're going to sync
//    [defaults synchronize];
    
    NSString *settingValue = [[NSUserDefaults standardUserDefaults] objectForKey: @"Testing"];
    NSLog(@"Test Results:  %@", settingValue);
    
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction)printDataAction: (id) sender
{
    Print *printSlateInfo = [[Print alloc] initWithQRSlateData:plistDictionary];
    [printSlateInfo printToPrinter];
    [printSlateInfo release];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction)importClipsButton: (id)sender
{
    NSOpenPanel *openDlg = [NSOpenPanel openPanel]; 
    
    NSArray* extensions = [[NSArray alloc] initWithObjects:@"mov", @"m4a", @"avi", @"qt", @"mp4", nil];
    
    [openDlg setAllowedFileTypes:extensions];
    [openDlg setExtensionHidden:NO];
    [openDlg setCanCreateDirectories:YES];
    [openDlg setAllowsMultipleSelection:YES];
    
    int result = (int)[openDlg runModal]; 
    
    if (result == NSOKButton)
    { 
        NSArray *files = [openDlg filenames];
        
        [self importMediaFiles:files];
        
    }
    
    [extensions release];
    
}

//-----------------------------------------------------------------------------------------------------------------------------------
// First Responder
- (IBAction)delete: (id)sender
{
    if (absoluteMoviePaths != nil || absoluteMoviePaths.count != 0)
        [self deleteTableRows];
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (IBAction)anaylzeMediaButton: (id)sender
{
    // Won't load the EXPORT LOCATION dialog unless there is a filetype selected, and there are movies in the list.
    if ((setExportXMLFCP7.state == 1 || setExportXMLFCPX.state == 1 || setExportXMLPremiere.state == 1 || setExportALE.state == 1) 
        && (absoluteMoviePaths != nil || absoluteMoviePaths.count != 0))
    {
        // Loads the user selected information into the dictionary for use.
        [self loadSessionUserInputIntoDictionary];
        
        // Loads the XML Save Modal and saves to fileLocationPath;
        [self saveDialogForEditorialFile];
    }
    
    // If XML and ALE are not selected, or if movies are not loaded.
    else
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Something is Missing!"];
        [alert setInformativeText:@"You must: \nSelect either XML or AFE (or both) for export. \nHave clips loaded for export."];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert runModal];
    }
    
    if ((fileLocationPath != nil) || ([fileLocationPath isEqualToString:@""]))
    {
        [self shouldButtonsBeEnabled:NO];
        
        // Sets the analyzing bar so that the 100% hits when all total path count reaches the top number.  
        [analyzeMediaProgress startAnimation:self];
        [analyzeMediaProgress setMinValue:-1];
        [analyzeMediaProgress setMaxValue:absoluteMoviePaths.count];
        
        // Determines the amount of processors/operations happening simultaneously.  
        [operationQueue setMaxConcurrentOperationCount:1];
        
        // Add Operation to Queue
        [operationQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
        
        for (int i = 0; i < [absoluteMoviePaths count]; i++) 
        {
            NSInvocationOperation* op = [[NSInvocationOperation alloc] 
                                         initWithTarget:self 
                                         selector:@selector(scanForQRCodesWithAbsolutePath:) 
                                         object:[absoluteMoviePaths objectAtIndex:i]];
            
            //Adds the operation to the operation queue
            [operationQueue addOperation:op];
            
            //We don't need the operation object anymore as the NSOperationQueue class retains the object
            [op release];
        }
        
        // NOTE:  When this finishes, it's monitored by ObserveValueForKeypath, 
        // where the prepareMediaForExportToNLE is initiated.  Yeah, it's confusing.
    }
    
    else
        NSLog(@"Need an Export File location.  Something is missing.");
}

#pragma mark - NSOperation Buttons, Methods, etc. 
//-----------------------------------------------------------------------------------------------------------------------------------
// This is invoked by the NSOperationQueue, and does the main scanning of QRCodes.
- (void) scanForQRCodesWithAbsolutePath:(NSString*)absoluteMoviePath
{
    //NSLog(@"This operation has been passed into the Queue.");
        
    ZXingReaderDevice* zxScanner = [[ZXingReaderDevice alloc] init];
    int qualityLevel = selectQuality.indexOfSelectedItem;  // Returns which Quality is selected by user from Interface.
    
    //Scans the Quicktime file at the these settings and then returns the info
    NSDictionary* qrScannerResults = [[NSDictionary alloc] initWithDictionary:
                           [zxScanner quicktimeProcessorAndScanner:absoluteMoviePath 
                                          qualityLevelOneThruThree:qualityLevel]];
    
    [qrStringSets addObject:qrScannerResults];
    [zxScanner release];
    [qrScannerResults release];    
}

//-----------------------------------------------------------------------------------------------------------------------------------
// Sets an observer that monitors changes to keypath values, in this case "operations" for the object operationQueue.
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
    int reverseOrder = [absoluteMoviePaths count] - [operationQueue.operations count];
    [analyzeMediaProgress setDoubleValue:(reverseOrder)];
    
    if (object == operationQueue && [keyPath isEqualToString:@"operations"]) 
    {
        if (reverseOrder == [absoluteMoviePaths count]) 
        {
            // The animated progress bar stops and the media is exported to the editorial file.
            [analyzeMediaProgress stopAnimation:self];
            [self prepareMediaForExportToNLE];  // Exports the XML or AFE to the NLE
            [self shouldButtonsBeEnabled:YES];  // Enables the Buttons for Use
            [self clearSession];  // Clears all the settings so that there's no doubling up.
            [operationQueue removeObserver:self forKeyPath:@"operations"];  // Remove the observer so it doesn't continue running.
            [self alertFinishedImport]; // Run an alert modal telling the user everything is done.
            [NSApp terminate:self];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object 
                               change:change context:context];
    }
}

#pragma mark - Local Methods
//-----------------------------------------------------------------------------------------------------------------------------------
- (void)saveDialogForEditorialFile
{
    
    // Create the File Save Dialog class. 
    NSSavePanel *saveDlg = [NSSavePanel savePanel]; 
    
    NSArray* extensions = [[NSArray alloc] initWithObjects:@"", nil];
    [saveDlg setAllowedFileTypes:extensions];

    [saveDlg setExtensionHidden:NO];
    [saveDlg setCanCreateDirectories:YES];
    [saveDlg setTitle:@"Save Dialog for Editorial Files"];
    
    int result = [saveDlg runModal]; 
    if (result == NSOKButton)
    { 
        NSURL *urlLocation = [saveDlg URL];
        fileLocationPath = [[NSString alloc] initWithString:[urlLocation absoluteString]];
    }
}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void) prepareMediaForExportToNLE
{
    
    SlateDataDictionary* masterDictionaryStart = [[SlateDataDictionary alloc] init];
    SlateDataDictionary* masterDictionaryFinal = [[SlateDataDictionary alloc] init];
             
    for (int i = 0; i < [qrStringSets count]; i++)
    {
        NSString* absoluteMoviePath = [[NSString alloc] initWithString:[[qrStringSets objectAtIndex:i] objectForKey:@"absolutePath"]];
        [masterDictionaryStart inputDataIntoSlateDictionary:[qrStringSets objectAtIndex:i]];   // Inputs found data in QR Code
        [masterDictionaryStart updateDataWithSlateFile:plistDictionary moviePath:absoluteMoviePath];  // Updates with Slate Data

        [absoluteMoviePath release];
    }
    
    //    [masterDictionaryFinal saveAsPlist];
    //    [plistDictionary writeToFile:@"/Users/augustanderson/Desktop/qrslatedata.plist" atomically:YES];
    
    NSString *clipInpointIsAtSlateClap = [[NSUserDefaults standardUserDefaults] objectForKey: @"clipInpointIsAtSlateClap"];    
    // If no .qrslate file was loaded, just use the found data.
    if ([plistFileLocation isEqualToString:@""] && [clipInpointIsAtSlateClap intValue] == 0)
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[masterDictionaryStart returnEntireDictionary]];
        [masterDictionaryFinal replaceDictionary:dict];
    }
    
    // If a .qrslate file was loaded for updating, then use the revisions window.
    else
    {
        // Load the REVISION MODAL to fix any mistakes.
        NSMutableDictionary *mainDict = [[NSMutableDictionary alloc] initWithDictionary:[masterDictionaryStart returnEntireDictionary]];
        NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] initWithDictionary:plistDictionary];
        
        Revisions *rev = [[Revisions alloc] initWithWindowNibName:@"Revisions"];
        [rev loadDataToRevision:dataDict QuicktimesDictionary:mainDict];
        rev.delegate = self;    
        [NSApp runModalForWindow:[rev window]];
        [mainDict release];
        [dataDict release];
        
        // When the MODAL is released, load in the result.
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:revisedDictionary];
        [masterDictionaryFinal replaceDictionary:dict];
        //[revDictLocal release];
    }
        
    FileWriter* fileWriter = [[FileWriter alloc] init];
    [fileWriter writeFileLocation:fileLocationPath];
    
    // Add the revised resulting clips into the XML or ALE
    for (int i = 0; i < [qrStringSets count]; i++)
    {
        NSString* absoluteMoviePath = [[NSString alloc] initWithString:[[qrStringSets objectAtIndex:i] objectForKey:@"absolutePath"]];
        
        if (setExportXMLFCP7.state == 1)
            [fileWriter addClipToXML:[masterDictionaryFinal returnClipDictionaryFromMasterDictionaryWithMoviePathKey:absoluteMoviePath]];
        if (setExportALE.state == 1)
            [fileWriter addClipToALE:[masterDictionaryFinal returnClipDictionaryFromMasterDictionaryWithMoviePathKey:absoluteMoviePath]];
        if (setExportXMLFCPX.state == 1)
            [fileWriter addClipToXMLFCPX:[masterDictionaryFinal returnClipDictionaryFromMasterDictionaryWithMoviePathKey:absoluteMoviePath] clipReference:i];
        
        [absoluteMoviePath release];
    }
    
    [masterDictionaryStart release];
    [masterDictionaryFinal release];
    
    
    if (setExportXMLFCP7.state == 1)
    {
        // Sets the Bin Name that all the media will be imported under.
        if ([plistDictionary objectForKey:@"Production Name"] != nil)
        {
            NSString *name = [[[NSString alloc] initWithFormat:@"QRSlate Importer - %@", [plistDictionary objectForKey:@"Production Name"]] autorelease];
            [fileWriter writeXMLToFile:name];
        }
        else
            [fileWriter writeXMLToFile:@"QRSlate Import"];
    }
    
    if (setExportALE.state == 1)
    {
        [fileWriter writeALEToFile];
    }
    
    if (setExportXMLFCPX.state == 1)
    {
        // Sets the Bin Name that all the media will be imported under.
        if ([plistDictionary objectForKey:@"Production Name"] != nil)
        {
            NSString *name = [[[NSString alloc] initWithFormat:@"QRSlate Importer - %@", [plistDictionary objectForKey:@"Production Name"]] autorelease];
            [fileWriter writeXMLFCPXToFile:name];
        }
        else
            [fileWriter writeXMLFCPXToFile:@"QRSlate Import"];
    }
    
    [fileWriter release];

}

//-----------------------------------------------------------------------------------------------------------------------------------
// REVISIONS delegate for returning information.        
- (void) returnRevisionResults:(NSMutableDictionary *)dict
{
    //NSLog(@"Returning:  %@", dict);
    revisedDictionary = [[NSMutableDictionary alloc] initWithDictionary:dict];
}


//-----------------------------------------------------------------------------------------------------------------------------------
- (void) shouldButtonsBeEnabled:(BOOL)boolValue
{
    [runButton setEnabled:boolValue];
    [clearCurrentSessionButton setEnabled:boolValue];
    [plistImportButton setEnabled:boolValue];
    [tableView setEnabled:boolValue];
    [selectQuality setEnabled:boolValue];
    [setInToOut setEnabled:boolValue];
    [setInAsSlateClap setEnabled:boolValue];    
    [setClipNameToSceneAndTake setEnabled:boolValue];
    [setMarkersEnabled setEnabled:boolValue];
    [setBinsEnabled setEnabled:boolValue];
    [setExportALE setEnabled:boolValue];
    [setExportXMLFCP7 setEnabled:boolValue];
    [setExportXMLFCPX setEnabled:boolValue];
    [setExportXMLPremiere setEnabled:boolValue];
    [setALEAudioFormat setEnabled:boolValue];
    [setALEVideoFormat setEnabled:boolValue];
    [setALEVideoFramerate setEnabled:boolValue];
    //[setSequencesEnabled setEnabled:boolValue];  // STILL WAITING TO ENABLE THIS
        
}

//-----------------------------------------------------------------------------------------------------------------------------------

- (void) loadSessionUserInputIntoDictionary
{
    NSNumber* numInToOut = [[NSNumber alloc] initWithInt:setInToOut.state];
    NSNumber* numInAsSlateClap = [[NSNumber alloc] initWithInt:setInAsSlateClap.state]; 
    NSNumber* numClipNameToSceneAndTake = [[NSNumber alloc] initWithInt:setClipNameToSceneAndTake.state];
    NSNumber* numBinsEnabled = [[NSNumber alloc] initWithInt:setBinsEnabled.state];
    NSNumber* numSequencesEnabled = [[NSNumber alloc] initWithInt:setSequencesEnabled.state];
    NSNumber* numMarkersEnabled = [[NSNumber alloc] initWithInt:setMarkersEnabled.state];
    NSNumber* numExportXMLFCP7 = [[NSNumber alloc] initWithInt:setExportXMLFCP7.state];
    NSNumber* numExportXMLFCPX = [[NSNumber alloc] initWithInt:setExportXMLFCPX.state];
    NSNumber* numExportXMLPremiere = [[NSNumber alloc] initWithInt:setExportXMLPremiere.state];
    NSNumber* numExportALE = [[NSNumber alloc] initWithInt:setExportALE.state];
    NSString* aleVideoFormat = [[NSString alloc] initWithString:[[setALEVideoFormat selectedCell] title]];
    NSString* aleVideoFramerate = [[NSString alloc] initWithString:[[setALEVideoFramerate selectedCell] title]];
    NSString* aleAudioFormat = [[NSString alloc] initWithString:[[setALEAudioFormat selectedCell] title]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:numClipNameToSceneAndTake forKey: @"clipNameAsSceneTake"];
    [defaults setObject:numInAsSlateClap forKey: @"clipInpointIsAtSlateClap"];
    [defaults setObject:numInToOut forKey: @"clipInOutIsSceneDuration"];
    [defaults setObject:numBinsEnabled forKey: @"useBins"];
    [defaults setObject:numSequencesEnabled forKey: @"useSequences"];
    [defaults setObject:numMarkersEnabled forKey: @"useMarkers"];
    [defaults setObject:numExportXMLFCP7 forKey: @"exportXMLFCP7"];
    [defaults setObject:numExportXMLFCPX forKey: @"exportXMLFCPX"];
    [defaults setObject:numExportXMLPremiere forKey: @"exportXMLPremiere"];
    [defaults setObject:numExportALE forKey: @"exportALEAvid"];
    [defaults setObject:aleVideoFormat forKey: @"aleVideoFormat"];
    [defaults setObject:aleVideoFramerate forKey: @"aleVideoFramerate"];
    [defaults setObject:aleAudioFormat forKey: @"aleAudioFormat"];
    
    [defaults synchronize];
}

//-----------------------------------------------------------------------------------------------------------------------------------
// Method will delete the selected rows.
- (void) deleteTableRows
{
    NSInteger x = [tableView selectedRow];
    
    NSIndexSet *selectedRows = [tableView selectedRowIndexes];
        
    [[arrayController mutableArrayValueForKey:@"content"] removeObjectsAtIndexes:selectedRows];
    [absoluteMoviePaths removeObjectsAtIndexes:selectedRows];
    
    // Moves the selected item.
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:x-1];
    [tableView selectRowIndexes:indexSet byExtendingSelection:NO];

}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void) importMediaFiles:(NSArray*)files
{
    // Initalizes absoluteMoviePaths if it hasn't been used yet.
    if (absoluteMoviePaths == nil)   
        absoluteMoviePaths = [[NSMutableArray alloc] init];
    
    // Perform operation using the list of files and adds them to the absoluteMoviePaths array.   
    for (int i = 0; i < [files count]; i++)
    {
        //Makes an array where the last object contains the filename.
        NSArray* separateFilename = [[files objectAtIndex:i] componentsSeparatedByString:@"/"];
        //Makes an Array where the last object contains the filename's extension.
        NSArray* arrayForFilenameExtension = [[separateFilename lastObject] componentsSeparatedByString:@"."];
        
        // Checks and will only accept files that are video files.  
        if ([[[arrayForFilenameExtension lastObject] lowercaseString] isEqualToString: @"mov"] ||
            [[[arrayForFilenameExtension lastObject] lowercaseString] isEqualToString: @"m4a"] ||
            [[[arrayForFilenameExtension lastObject] lowercaseString] isEqualToString: @"avi"] ||
            [[[arrayForFilenameExtension lastObject] lowercaseString] isEqualToString: @"qt"] ||
            [[[arrayForFilenameExtension lastObject] lowercaseString] isEqualToString: @"mp4"])
        {
            
            [arrayController addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [files objectAtIndex:i], @"path", 
                                        [separateFilename lastObject], @"filename", 
                                        nil]];
            
            if (absoluteMoviePaths != nil)
                [absoluteMoviePaths addObject:[files objectAtIndex:i]];
        }
        
        else
            NSLog(@"%@ is not a valid file.", [separateFilename lastObject]);
    }

}

//-----------------------------------------------------------------------------------------------------------------------------------
- (void) alertFinishedImport
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Import Is Finished!"];
    [alert setInformativeText:@"Now load the file into your Editorial Software."];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert runModal];
}

@end
