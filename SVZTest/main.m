//
//  main.m
//  SVZTest
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SevenZip/SevenZip.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        SVZArchive* archive = [SVZArchive archiveWithURL:[NSURL fileURLWithPath:@"/Users/lvsti/stuff.7z"]
                                                   error:NULL];
        [archive addFileAtURL:[NSURL fileURLWithPath:@"/Users/lvsti/respoof"]];
    }
    return 0;
}
