//
//  Print.h
//  QRSlate-App
//
//  Created by August Anderson on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Print : NSObject
{
    NSDictionary *qrslateData;
}

- (id) initWithQRSlateData:(NSDictionary*)dict;
- (void) printToPrinter;

@end
