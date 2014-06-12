//
//  PrintCell.h
//  QRSlate_Print
//
//  Created by August Anderson on 11/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PrintCell : NSViewController
{
    IBOutlet NSTextField *camRoll;
    IBOutlet NSTextField *scene;
    IBOutlet NSTextField *take;
    IBOutlet NSTextField *sndRoll;
    IBOutlet NSTextField *circleTake;
    IBOutlet NSTextField *duration;
    IBOutlet NSTextField *lens;
    IBOutlet NSTextField *description;
    IBOutlet NSTextField *comments;
    
    NSDictionary* takeDict;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andDictionary:(NSDictionary*)dict;

@end
