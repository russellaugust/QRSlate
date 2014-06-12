//
//  NSMutableString+XmlEscape.h
//  QRSlate-App
//
//  Created by cht on 4/2/13.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableString (XmlEscape)
-(NSMutableString *) xmlSimpleUnescape;
-(NSMutableString *) xmlSimpleEscape;
@end


@interface NSString (XmlEscape)
-(NSString *) xmlSimpleUnescape;
-(NSString *) xmlSimpleEscape;
@end