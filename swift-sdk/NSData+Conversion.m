//
//  NSData+Conversion.m
//  Iterable-iOS-SDK
//
//  Created by Ilya Brin on 2/6/15.
//  Copyright (c) 2015 Iterable. All rights reserved.
//

// http://stackoverflow.com/questions/1305225/best-way-to-serialize-a-nsdata-into-an-hexadeximal-string

// If this is part of a static library, you need to add -all_load to the Other Linker Flags build setting.
// http://stackoverflow.com/questions/3998483/objective-c-category-causing-unrecognized-selector

#import "NSData+Conversion.h"

@implementation NSData (NSData_Conversion)

#pragma mark - String Conversion

// documented in NSData+Conversion.h
- (NSString *)ITEHexadecimalString
{
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [self length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}

@end
