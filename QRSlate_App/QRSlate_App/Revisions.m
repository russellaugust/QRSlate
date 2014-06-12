//
//  Revisions.m
//  QRSlate_Print
//
//  Created by August Anderson on 11/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Revisions.h"
#import "QTTimeConvert.h"

@implementation Revisions

@synthesize delegate;

#define MyPrivateTableViewDataType @"MyPrivateTableViewDataType"

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
        
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void) awakeFromNib 
{
    [quicktimesList registerForDraggedTypes:[NSArray arrayWithObject:MyPrivateTableViewDataType]];
    [unusedDataList registerForDraggedTypes:[NSArray arrayWithObject:MyPrivateTableViewDataType]];
    
    // Checks the user default settings for whether or not to enable the SET CLAP Button.
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"clipInpointIsAtSlateClap"] intValue] == 0)
    {
        [nsButtonSetClap setHidden:YES];
        [helpSetClap setHidden:YES];
    }
    
}

//---------------------------------------------------------------------------------------------------------------------------
#pragma mark - Tableview Data Source Methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == quicktimesList)    
        return mainQTArray.count;
    
    else if (aTableView == unusedDataList)    
        return unusedDataArray.count;
    
    else 
        return 0;
}

//---------------------------------------------------------------------------------------------------------------------------
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    // Display generated for QUICKTIMES LIST
    if (aTableView == quicktimesList)
    {
        if (aTableColumn == quicktimeListQuicktimeFiles)
        {
            NSString *string = [[NSString alloc] initWithString:[[mainQTArray objectAtIndex:rowIndex] objectForKey:@"Filename"]];
            return string;
        }
        
        else
        {
            if (![[[mainQTArray objectAtIndex:rowIndex] objectForKey:@"Scene"] isEqualToString:@""])
            {
                NSString *string = [[NSString alloc] initWithFormat:@"%@/%@", [[mainQTArray objectAtIndex:rowIndex] objectForKey:@"Scene"],
                                                                              [[mainQTArray objectAtIndex:rowIndex] objectForKey:@"Take"]];
                return string;
            }
            
            else
            {
                NSString *string = [[NSString alloc] initWithString:@""];
                return string;
            }
        }
    }

    // Display generated for UNUSED DATA LIST
    else if (aTableView == unusedDataList)
    {
        NSString *unusedData = [[NSString alloc] initWithFormat:@"%@/%@", [[unusedDataArray objectAtIndex:rowIndex] objectForKey:@"Scene"], 
                                                                     [[unusedDataArray objectAtIndex:rowIndex] objectForKey:@"Take"]];
        return unusedData;
    }
    
    else
        return 0;

}

//---------------------------------------------------------------------------------------------------------------------------
// Used to Sort the Column.
-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors 
{       
    NSArray *newDescriptors = [tableView sortDescriptors];
    [mainQTArray sortUsingDescriptors:newDescriptors]; 
    [tableView reloadData]; 
}

//---------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    // Used to set the color of the tableview text, RED for changeable, BLACK for locked connection.
    if (aTableView == quicktimesList)
    {
        if ([[[mainQTArray objectAtIndex:rowIndex] objectForKey:@"Updated with File"] isEqualToString:@"YES"])
        {
            [aCell setTextColor:[NSColor blackColor]];
        }
        
        else
            [aCell setTextColor:[NSColor redColor]];
        
    }
}

//---------------------------------------------------------------------------------------------------------------------------
#pragma mark - Tableview Drag and Drop Methods
// Drag and Drop Operations
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // Only allows dragging on the Data List.
    if (tv == unusedDataList)
    {
        // Copy the row numbers to the pasteboard.
        NSData *zNSIndexSetData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
        [pboard declareTypes:[NSArray arrayWithObject:MyPrivateTableViewDataType] owner:self];
        [pboard setData:zNSIndexSetData forType:MyPrivateTableViewDataType];
        return YES;
    }
    
    else
        return NO;
}

//---------------------------------------------------------------------------------------------------------------------------
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row 
       proposedDropOperation:(NSTableViewDropOperation)op
{
    // Only allows dropping on the Quicktimes List
    if (tv == quicktimesList)
    {
        // Validates the drop area, whether or not something can drop there, or between.
        int result;
        
        // Will allow the drop if the drop area is ON the cell, and if info in the cell contains an ID Number (***revise this***).
        if (op == NSTableViewDropOn && [[[mainQTArray objectAtIndex:row] objectForKey:@"Updated with File"] isEqualToString:@"NO"])
            result = NSDragOperationMove;
        
        else
            result = NSDragOperationNone;
        
        return result;

    }
    
    else
        return NSDragOperationNone;

}

//---------------------------------------------------------------------------------------------------------------------------
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    // Only allows dropping on the Quicktimes List.
    if (aTableView == quicktimesList)
    {
        NSPasteboard* pboard = [info draggingPasteboard];
        NSData* rowData = [pboard dataForType:MyPrivateTableViewDataType];
        NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
        NSInteger dragRow = [rowIndexes firstIndex];
        
        // If ID Number is Equal to Nothing, then you can drop items on the QT row.
        if ([[[mainQTArray objectAtIndex:row] objectForKey:@"ID Number"] isEqualToString:@""])
        {
            [self linkDataToQuicktime:[mainQTArray objectAtIndex:row] fromUnusedData:[unusedDataArray objectAtIndex:dragRow]];
            
            [usedDataArray addObject:[unusedDataArray objectAtIndex:dragRow]];  // Add the data being deleted for backup.
            [unusedDataArray removeObjectAtIndex:dragRow]; // Remove the data from the Unused Data list.
            
            [quicktimesList reloadData];
            [unusedDataList reloadData];
            return YES;
        }
        
        // If ID Number is there, then you may not drop items on the QT row.
        else
        {
            // Eventually, have this SWAP instead of just stonewall.
            return NO;
        }
    }
    
    else
        return NO;
    
}

//---------------------------------------------------------------------------------------------------------------------------
- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    // If the user is selecting in the QT List
    if (tableView == quicktimesList)
    {        
        // instantiate a new movie from the selected file path
        QTMovie *newMovie = [QTMovie movieWithFile:[[mainQTArray objectAtIndex:row] objectForKey:@"File Path"] error:NULL];
        
        // were we able to properly instantiate a new QTMovie?
        if (newMovie)
        {
            if (mMovie)
            {
                [mMovie release];	// release existing movie
            }
            [newMovie retain];
            mMovie = newMovie;	// save new movie
            
            [self setDataSectionFields:[mainQTArray objectAtIndex:row]];
            
            [mMovieView setMovie: mMovie];   // set this new movie on the view
            
        }
        
        // Disables or Enables the DISCONNECT Button if the data was linked prior to the REVISION MODAL opening.
        if ([[[mainQTArray objectAtIndex:row] objectForKey:@"Updated with File"] isEqualToString:@"NO"])
            [nsButtonDisconnectData setEnabled:YES];
        else
            [nsButtonDisconnectData setEnabled:NO];
        
    }
    
    // If user selects in the Unused Data List
    else if (tableView == unusedDataList)
    {
        [self setDataSectionFields:[unusedDataArray objectAtIndex:row]];
        [mMovieView setMovie:nil];        
    }
    
    return YES;
}

//---------------------------------------------------------------------------------------------------------------------------
#pragma mark - Buttons

- (IBAction)buttonSetClap:(id)sender
{        
    QTTimeConvert *qtConvert = [[QTTimeConvert alloc] initWithMovie:mMovie];
    int currentFrame = [qtConvert returnIntegerOfLocationUsingQTTime:[mMovie currentTime]];
    currentFrame++; // TO compensate for the video starting at frame 0. 
    
    NSString *currentFrameSelected = [[NSString alloc] initWithFormat:@"%i", currentFrame];
    [[mainQTArray objectAtIndex:[quicktimesList selectedRow]] setObject:currentFrameSelected forKey:@"Clip Slate Clap Location in Frames"];
    
    [textfieldSlateClap setStringValue:currentFrameSelected];
}

//---------------------------------------------------------------------------------------------------------------------------
- (IBAction)buttonFinished:(id)sender
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (int x=0; x < mainQTArray.count; x++)
        [dict setObject:[mainQTArray objectAtIndex:x] forKey:[[mainQTArray objectAtIndex:x] objectForKey:@"File Path"]];
    
    [delegate returnRevisionResults:dict];
    // Finishes out the actions, user is done revising the data.
    [self.window orderOut:nil];
    [NSApp endSheet:self.window];
    [NSApp stopModal];
}

//---------------------------------------------------------------------------------------------------------------------------
- (IBAction)disconnectDataFromQT:(id)sender
{
    NSInteger selectedRow = [quicktimesList selectedRow];

    [self deleteQTFieldAtRow:[quicktimesList selectedRow]];
    
    [self setDataSectionFields:[mainQTArray objectAtIndex:selectedRow]];
}

//---------------------------------------------------------------------------------------------------------------------------
- (IBAction)delete:(id)sender
{
    NSInteger selectedRow = [quicktimesList selectedRow];
    
    [self deleteQTFieldAtRow:[quicktimesList selectedRow]];
    
    [self setDataSectionFields:[mainQTArray objectAtIndex:selectedRow]];

}
//---------------------------------------------------------------------------------------------------------------------------
#pragma mark - Methods
// Removes the QT File at a selected row.  
- (void) deleteQTFieldAtRow:(NSInteger)selectedRow
{
    // Iterates through the unusedDataArray for finding ID Numbers connections.
    for (int x=0; x<usedDataArray.count; x++)
    {
        if ([[[usedDataArray objectAtIndex:x] objectForKey:@"ID Number"] isEqualToString:[[mainQTArray objectAtIndex:selectedRow] objectForKey:@"ID Number"]])
        {            
            [unusedDataArray addObject:[usedDataArray objectAtIndex:x]];  // Add the data from the deleted list back to the real list.
            [usedDataArray removeObjectAtIndex:x];
            
            NSDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[mainQTArray objectAtIndex:selectedRow]];
            NSArray *keys = [dict allKeys];
            for (int y=0; y<keys.count; y++)
            {
                // Does not replace fields listed below, as these are generic, universal fields.
                if ([[keys objectAtIndex:y] isEqualToString:@"Filename"] ||
                    [[keys objectAtIndex:y] isEqualToString:@"File Path"] ||
                    [[keys objectAtIndex:y] isEqualToString:@"Updated with File"] ||
                    [[keys objectAtIndex:y] isEqualToString:@"Clip Duration in Frames"] ||
                    [[keys objectAtIndex:y] isEqualToString:@"Clip Slate Clap Location in Frames"] ||
                    [[keys objectAtIndex:y] isEqualToString:@"Clip Timebase"])
                {
                    //NSLog(@"Was equal to 'Filename', 'File Path', or 'Updated with File'");
                }
                
                // If the dictionary has nothing in it, do nothing.  
                else if ([dict objectForKey:[keys objectAtIndex:y]] == nil)
                {
                    //NSLog(@"Nil Object.  Keeping what was in QT Dictionary.");
                }
                
                // Replace the currently selected Dictionary Field.
                else
                    [[mainQTArray objectAtIndex:selectedRow] setObject:@"" forKey:[keys objectAtIndex:y]];                
            }
        }
    }
    
    // Sorts the UnusedDataArray by it's ID Numbers.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ID Number" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [unusedDataArray sortUsingDescriptors:sortDescriptors];
    
    // Refreshes the NSTableView Lists.
    [quicktimesList reloadData];
    [unusedDataList reloadData];

}

//---------------------------------------------------------------------------------------------------------------------------
// Used EXTERNALLY to load the two sets of data into the class. (Probably should be in the INIT, figure that out)
- (void) loadDataToRevision:(NSDictionary*)qrslateDict QuicktimesDictionary:(NSDictionary*)qtDict
{
    NSArray *allKeys = [qtDict allKeys];
    NSMutableArray *existingIDs = [[NSMutableArray alloc] init];
    
    // Iterate through all Quicktimes
    for (int x = 0; x < allKeys.count; x++)
    {
        NSString *qtPath = [[NSString alloc] initWithString:[allKeys objectAtIndex:x]];
        NSDictionary *singleQTDict = [[NSDictionary alloc] initWithDictionary:[qtDict objectForKey:qtPath]];
        
        // Iterate through Takes to compare the ID to the Quicktime
        int takesCount = (int)[[qrslateDict objectForKey:@"All Takes"] count];
        for (int y = 0; y < takesCount; y++)
        {
            NSString *dataIDNum = [[NSString alloc] 
                                   initWithString:[[[qrslateDict objectForKey:@"All Takes"] objectAtIndex:y] objectForKey:@"ID Number"]];
            NSString *qtIDNum = [[NSString alloc] 
                                 initWithString:[singleQTDict objectForKey:@"ID Number"]];
            
            // If the ID Numbers are a match, add that number to the EXISTING IDS list.
            if ([qtIDNum isEqualToString:dataIDNum])
                [existingIDs addObject:dataIDNum];
        }
    }
    
    NSMutableArray *unusedTakes = [[NSMutableArray alloc] init];
    int takesCount = (int)[[qrslateDict objectForKey:@"All Takes"] count];

    // Starts an iteration through the Takes again.
    for (int x = 0;  x < takesCount; x++)
    {
        NSMutableDictionary *takeDict = [[NSMutableDictionary alloc] initWithDictionary:[[qrslateDict objectForKey:@"All Takes"] objectAtIndex:x]];
        
        // Begins an iteration through the IDs that were found in the previous loop.
        BOOL idsEqual = NO;
        for (int y = 0;  y < existingIDs.count; y++)
        {
            NSString *existingIDNum = [[NSString alloc] initWithString:[existingIDs objectAtIndex:y]];

            // Compares the slate data with the currently found ID numbers and looks any similar ones in order to
            // produce a set that has all unused takes.
            if ([existingIDNum isEqualToString:[takeDict objectForKey:@"ID Number"]])
                idsEqual = YES;
        }
        
        if (!idsEqual)
            [unusedTakes addObject:takeDict]; // Adds the current object to the group of unused takes.
    }
    
    usedDataArray = [[NSMutableArray alloc] init];
    unusedDataArray = [[NSMutableArray alloc] initWithArray:unusedTakes];
    mainDict = [[NSMutableDictionary alloc] initWithDictionary:qtDict];
    
    // Pulls the filenames from they KEYS and adds them as an entry for access later.
    NSArray *qtPaths = [[NSArray alloc] initWithArray:[mainDict allKeys]];
    for (int x=0; x<mainDict.count; x++)
    {
        NSString *splitting = [[NSString alloc] initWithString:[qtPaths objectAtIndex:x]];
        NSArray *splitted = [[NSArray alloc] initWithArray:[splitting componentsSeparatedByString:@"/"]];
        NSString *filename = [splitted lastObject];
        [[mainDict objectForKey:[qtPaths objectAtIndex:x]] setObject:filename forKey:@"Filename"];
        [[mainDict objectForKey:[qtPaths objectAtIndex:x]] setObject:[qtPaths objectAtIndex:x] forKey:@"File Path"];
    }
    
    NSArray *allValues = [mainDict allValues];
    mainQTArray = [[NSMutableArray alloc] initWithArray:allValues];

}

//---------------------------------------------------------------------------------------------------------------------------
// Receives an entry from the QT array and an entry from the UNUSED DATA array, updates the QT entry, and returns it.
- (NSMutableDictionary*) linkDataToQuicktime:(NSMutableDictionary*)qtDict fromUnusedData:(NSMutableDictionary*)dataDict
{
    // Iterate through qtDict's keys
    NSArray *keys = [qtDict allKeys];
    for (int x=0; x<keys.count; x++)
    {
        NSLog(@"******* KEY = %@ ***********", [keys objectAtIndex:x]);
        if ([[keys objectAtIndex:x] isEqualToString:@"Filename"] ||
            [[keys objectAtIndex:x] isEqualToString:@"File Path"] ||
            [[keys objectAtIndex:x] isEqualToString:@"Updated with File"])
        {
            NSLog(@"Was equal to 'Filename', 'File Path', or 'Updated with File'");
        }
        
        else if ([dataDict objectForKey:[keys objectAtIndex:x]] == nil)
        {
            NSLog(@"Nil Object.  Keeping what was in QT Dictionary for %@.", [keys objectAtIndex:x]);
        }
                
        else
        {
            NSLog(@"%@ was added.", [keys objectAtIndex:x]);
            NSString *object = [[NSString alloc] initWithString:[dataDict objectForKey:[keys objectAtIndex:x]]];
            [qtDict setObject:object forKey:[keys objectAtIndex:x]];
        }
        
    }
    
    if ([dataDict objectForKey:@"Markers"])
    {
        NSLog(@"+++++++++++ There MARKERS in this here file. +++++++++++");
        NSArray *object = [[NSArray alloc] initWithArray:[dataDict objectForKey:@"Markers"]];
        [qtDict setObject:object forKey:@"Markers"];
    }

    
    return qtDict;
}

//---------------------------------------------------------------------------------------------------------------------------
// Set Data in Edit Section
- (void) setDataSectionFields:(NSMutableDictionary*)dict
{
    [textfieldActionInpoint setStringValue:[dict objectForKey:@"Action Inpoint"]];
    [textfieldActionOutpoint setStringValue:[dict objectForKey:@"Action Outpoint"]];
    [textfieldCameraRoll setStringValue:[dict objectForKey:@"Camera Roll"]];
    [textfieldCircleTake setStringValue:[dict objectForKey:@"Circle Take"]];
    [textfieldFPS setStringValue:[dict objectForKey:@"FPS"]];
    [textfieldIDNumber setStringValue:[dict objectForKey:@"ID Number"]];
    [textfieldIntExt setStringValue:[dict objectForKey:@"Int Ext"]];
    [textfieldLensFilters setStringValue:[dict objectForKey:@"Lens Filters"]];
    [textfieldLocation setStringValue:[dict objectForKey:@"Location"]];
    [textfieldMOS setStringValue:[dict objectForKey:@"MOS"]];
    [textfieldScene setStringValue:[dict objectForKey:@"Scene"]];
    [textfieldSceneDuration setStringValue:[dict objectForKey:@"Scene Duration"]];
    [textfieldShotComment setStringValue:[dict objectForKey:@"Shot Comment"]];
    [textfieldShotDescription setStringValue:[dict objectForKey:@"Shot Description"]];
    [textfieldShotType setStringValue:[dict objectForKey:@"Shot Type"]];
    [textfieldSoundRoll setStringValue:[dict objectForKey:@"Sound Roll"]];
    [textfieldTake setStringValue:[dict objectForKey:@"Take"]];
    [textfieldTakeQuality setStringValue:[dict objectForKey:@"Take Quality"]];
    [textfieldTimeofDay setStringValue:[dict objectForKey:@"Time of Day"]];
    
    if ([dict objectForKey:@"Filename"] != nil)
        [textfieldFilename setStringValue:[dict objectForKey:@"Filename"]];
    else
        [textfieldFilename setStringValue:@""];
    
    // If there is a Slate Clap location, set the Quicktime Viewer to that location.
    if ([dict objectForKey:@"Clip Slate Clap Location in Frames"] != nil)
    {
        [textfieldSlateClap setStringValue:[dict objectForKey:@"Clip Slate Clap Location in Frames"]];
        QTTimeConvert *qtConvert = [[QTTimeConvert alloc] initWithMovie:mMovie];
        QTTime time = [qtConvert returnQTTimeOfLocationUsingFramecount:[[dict objectForKey:@"Clip Slate Clap Location in Frames"] intValue]];

        [mMovie setCurrentTime:time];
    }
    else
        [textfieldSlateClap setStringValue:@""];

}


@end