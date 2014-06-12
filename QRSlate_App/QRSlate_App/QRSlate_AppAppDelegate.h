//
//  QRSlate_AppAppDelegate.h
//  QRSlate_App
//
//  Created by August Anderson on 6/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MainWindowController.h"

@interface QRSlate_AppAppDelegate : NSObject <NSApplicationDelegate> {
@private
    
    NSWindow             *window;
    MainWindowController *mainWindow;
        
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)newWindow: (id) sender;

- (BOOL) appWorksFrom:(int)dateIn until:(int)dateOut;

@end
