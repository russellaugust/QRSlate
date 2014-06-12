//
//  Print.m
//  QRSlate-App
//
//  Created by August Anderson on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Print.h"
#import <WebKit/WebKit.h>

@implementation Print

- (id) initWithQRSlateData:(NSDictionary*)dict
{
    qrslateData = [[NSDictionary alloc] initWithDictionary:dict];
    return self;
}

- (void) printToPrinter
{
    NSMutableString *htmlString = [[NSMutableString alloc] initWithString:@"<html>"];
    
    [htmlString appendString:@"<html xmlns=\"http://www.w3.org/1999/xhtml\">"];
    [htmlString appendString:@"<head>"];
    [htmlString appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />"];
    [htmlString appendString:@"<title>Untitled Document</title>"];
    [htmlString appendString:@"<style type=\"text/css\">"];
    [htmlString appendString:@"body,td,th {"];
    [htmlString appendString:@"	font-family: \"Lucida Sans Unicode\", \"Lucida Grande\", sans-serif;"];
    [htmlString appendString:@"	font-size: 12px;"];
    [htmlString appendString:@"}"];
    
    [htmlString appendString:@".movietitle {"];
    [htmlString appendString:@"	font-family: \"Lucida Sans Unicode\", \"Lucida Grande\", sans-serif;"];
    [htmlString appendString:@"	font-size: 15px;"];
    [htmlString appendString:@"	font-weight: bold;"];
    [htmlString appendString:@"	color: #000;"];
    [htmlString appendString:@"}"];
    [htmlString appendString:@"</style>"];
    [htmlString appendString:@"</head>"];
    [htmlString appendString:@"<body>"];
    
    [htmlString appendString:@"<table width=\"877\" border=\"0\" cellpadding=\"3\" align=\"left\">"];
    [htmlString appendString:@"  <tr>"];
    [htmlString appendString:@"  	<td align=\"center\"><p>SCRIPT SUPERVISOR'S DAILY LOG</p>"];
    [htmlString appendFormat:@"    <p class=\"movietitle\"><strong>%@</strong></p></td>", [qrslateData objectForKey:@"Production Name"]];
    [htmlString appendString:@"  </tr>"];
    [htmlString appendString:@"</table>"];
    
    [htmlString appendString:@"<table width=\"877\" border=\"0\" cellpadding=\"3\" align=\"left\">"];
    [htmlString appendString:@"  <tr>"];
    [htmlString appendFormat:@"    <td width=\"599\" align=\"left\" valign=\"top\">Director: %@<br />Director of Photography: %@<br /><br /></td>", [qrslateData objectForKey:@"Director"], [qrslateData objectForKey:@"Director of Photography"]];
    [htmlString appendFormat:@"	<td width=\"260\" align=\"left\" valign=\"top\">Producer: %@</td>", [qrslateData objectForKey:@"Producer"]];
    [htmlString appendString:@"  </tr>"];
    [htmlString appendString:@"</table>"];
    
    [htmlString appendString:@"<table width=\"877\" border=\"1\" cellpadding=\"3\" align=\"left\" frame=\"border\" rules=\"all\">"];
    [htmlString appendString:@"  <tr>"];
    [htmlString appendString:@"    <td align=\"left\"><strong>CAM</strong></td>"];
    [htmlString appendString:@"    <td align=\"left\"><strong>SCENE</strong></td>"];
    [htmlString appendString:@"    <td align=\"left\"><strong>TAKE</strong></td>"];
    [htmlString appendString:@"    <td align=\"left\"><strong>SND</strong></td>"];
    [htmlString appendString:@"    <td align=\"left\"><strong>QUALITY</strong></td>"];
    [htmlString appendString:@"    <td align=\"left\"><strong>TIME</strong></td>"];
    [htmlString appendString:@"    <td align=\"left\"><strong>LENS</strong></td>"];
    [htmlString appendString:@"    <td align=\"left\"><strong>DESCRIPTION</strong></td>"];
    [htmlString appendString:@"    <td align=\"left\"><strong>COMMENTS</strong></td>"];
    [htmlString appendString:@"  </tr>"];
    
    for (int x=0; x<[[qrslateData objectForKey:@"All Takes"] count]; x++)
    {
        NSDictionary *dict = [[qrslateData objectForKey:@"All Takes"] objectAtIndex:x];
        
        [htmlString appendString:@"<tr>"];
        [htmlString appendFormat:@"<td align=\"left\" valign=\"middle\">%@</td>", [dict objectForKey:@"Camera Roll"]];
        [htmlString appendFormat:@"<td align=\"left\" valign=\"middle\">%@</td>", [dict objectForKey:@"Scene"]];
        [htmlString appendFormat:@"<td align=\"left\" valign=\"middle\">%@</td>", [dict objectForKey:@"Take"]];
        [htmlString appendFormat:@"<td align=\"left\" valign=\"middle\">%@</td>", [dict objectForKey:@"Sound Roll"]];
        [htmlString appendFormat:@"<td align=\"left\" valign=\"middle\">%@</td>", [dict objectForKey:@"Take Quality"]];
        [htmlString appendFormat:@"<td align=\"left\" valign=\"middle\">%@</td>", [dict objectForKey:@"Scene Duration"]];
        [htmlString appendFormat:@"<td align=\"left\" valign=\"middle\">%@</td>", [dict objectForKey:@"Lens Filters"]];
        [htmlString appendFormat:@"<td align=\"left\" valign=\"middle\">%@</td>", [dict objectForKey:@"Shot Description"]];
        [htmlString appendFormat:@"<td align=\"left\" valign=\"middle\">%@</td>", [dict objectForKey:@"Shot Comment"]];
        [htmlString appendString:@"  </tr>"];
        
    }
    
    [htmlString appendString:@"</table>"];
    [htmlString appendString:@"</body>"];
    [htmlString appendString:@"</html>"];
    
    // Creating the webview that will contain the printout.
    WebView *webView = [[WebView alloc] initWithFrame: NSMakeRect(0, 0, (6.5 * 72), (9 * 72))];
    [[webView mainFrame] loadHTMLString:htmlString baseURL: nil];
    
    // Allows the HTML to load before displaying it.
    while ([webView isLoading])
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        [webView setNeedsDisplay:NO];
        [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate dateWithTimeIntervalSinceNow:1.0] inMode:NSDefaultRunLoopMode dequeue:YES];
        [pool drain];
    }
    
    [webView setNeedsDisplay:YES];
    
    // Load the printer settings.
    NSPrintInfo* printInfo = [[NSPrintInfo alloc] init];
    
    [printInfo setOrientation:0]; // Sets Page Orientation to Portrait
    [printInfo setScalingFactor:1.0];
    
    [printInfo setRightMargin:30.0];
    [printInfo setLeftMargin:30.0];
    [printInfo setTopMargin:30.0];
    [printInfo setBottomMargin:30.0];
    
    // Load the printer queue and add the webview to it.  Note that its adding the webview's Document View so it includes everything.
    NSPrintOperation *po = [NSPrintOperation printOperationWithView:[[[webView mainFrame] frameView] documentView] printInfo:printInfo];
    
    [po showsPrintPanel];
    [po runOperation];
}

@end
