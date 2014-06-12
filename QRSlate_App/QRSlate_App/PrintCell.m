//
//  PrintCell.m
//  QRSlate_Print
//
//  Created by August Anderson on 11/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PrintCell.h"

@implementation PrintCell

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andDictionary:(NSDictionary *)dict
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        takeDict = [[NSDictionary alloc] initWithDictionary:dict];
    }
    
    return self;
}

- (void) awakeFromNib
{
    [camRoll setStringValue:[takeDict objectForKey:@"Camera Roll"]];
    [scene setStringValue:[takeDict objectForKey:@"Scene"]];
    [take setStringValue:[takeDict objectForKey:@"Take"]];
    [sndRoll setStringValue:[takeDict objectForKey:@"Sound Roll"]];
    [circleTake setStringValue:[takeDict objectForKey:@"Take Quality"]];
    [duration setStringValue:[takeDict objectForKey:@"Scene Duration"]];
    [lens setStringValue:[takeDict objectForKey:@"Lens Filters"]];
    [description setStringValue:[takeDict objectForKey:@"Shot Description"]];
    [comments setStringValue:[takeDict objectForKey:@"Shot Comment"]];
    
}

@end
