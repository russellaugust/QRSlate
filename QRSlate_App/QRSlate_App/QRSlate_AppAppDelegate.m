//
//  QRSlate_AppAppDelegate.m
//  QRSlate_App
//
//  Created by August Anderson on 6/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "QRSlate_AppAppDelegate.h"

@implementation QRSlate_AppAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Sets the Tool Tips Popup Time to 300ms so they appear faster.
    [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: 200]
                                              forKey: @"NSInitialToolTipDelay"];
        
    // Opens initial window.
    mainWindow = [[MainWindowController alloc] initWithWindowNibName:@"QRSlateViewController"];
    [[mainWindow window] makeMainWindow];
    
//    NSDictionary *defaultsDict = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
//    for (NSString *key in [defaultsDict allKeys])
//        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    
/*    // Opens initial window with TIME LIMITER    
    NSString *cProtection = [[NSUserDefaults standardUserDefaults] objectForKey: @"kCopyProtection"];    
    if ([self appWorksFrom:20120321 until:20120321] && [cProtection intValue] < 5)
    {
        int x = [cProtection intValue] + 1;
        NSString *newCProtection = [[NSString alloc] initWithFormat:@"%i", x];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:newCProtection forKey: @"kCopyProtection"]; // The forKey is the name of the setting you're going to sync
        [defaults synchronize];
        
        mainWindow = [[MainWindowController alloc] initWithWindowNibName:@"QRSlateViewController"];
        [[mainWindow window] makeMainWindow];        
    }
    
    else
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"EXPIRED"];
        [alert setInformativeText:@"Please DELETE THIS FILE and continue using the purchased version."];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert runModal];
        
        [NSApp terminate:self];
     }*/

}

//-------------------------------------------------------------------------------------------------------------------------
- (IBAction)newWindow: (id) sender
{
    mainWindow = [[MainWindowController alloc] initWithWindowNibName:@"QRSlateViewController"];
    [[mainWindow window] makeMainWindow];
}

//-------------------------------------------------------------------------------------------------------------------------
- (BOOL) appWorksFrom:(int)dateIn until:(int)dateOut
{
    NSDate* currentDate = [NSDate date];
    NSDateFormatter* formatter = [[[NSDateFormatter alloc] init]autorelease];
    [formatter setDateFormat:@"yyyyMMdd"];
    
    NSInteger currentDateInt = [[formatter stringFromDate:currentDate] intValue];

    if (currentDateInt >= dateIn && currentDateInt <= dateOut)
        return YES;
    else
        return NO;

}

@end
