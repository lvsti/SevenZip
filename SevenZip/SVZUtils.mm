//
//  SVZUtils.m
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "SVZUtils.h"


NSString* FromUString(const UString& ustr) {
    NSData* ustrBuf = [NSData dataWithBytesNoCopy:(void*)ustr.Ptr()
                                           length:ustr.Len()*sizeof(wchar_t)
                                     freeWhenDone:NO];
    return [[NSString alloc] initWithData:ustrBuf encoding:NSUTF32LittleEndianStringEncoding];
}

UString ToUString(NSString* str) {
    NSUInteger byteCount = [str lengthOfBytesUsingEncoding:NSUTF32LittleEndianStringEncoding];
    wchar_t* buf = (wchar_t*)malloc(byteCount + sizeof(wchar_t));
    buf[str.length] = 0;
    [str getBytes:buf
        maxLength:byteCount
       usedLength:NULL
         encoding:NSUTF32LittleEndianStringEncoding
          options:0
            range:NSMakeRange(0, str.length)
   remainingRange:NULL];
    UString ustr(buf);
    free(buf);

    return ustr;
}
