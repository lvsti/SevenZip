//
//  main.m
//  SVZTest
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SevenZip/SevenZip.h>

int TestCreateArchive(int argc, const char* argv[]) {
    if (argc < 3) {
        return 1;
    }

    NSString* archiveName = [NSString stringWithUTF8String:argv[1]];
    NSMutableArray* fileArgs = [NSMutableArray arrayWithCapacity:argc-2];
    for (int i = 2; i < argc; ++i) {
        [fileArgs addObject:[NSString stringWithUTF8String:argv[i]]];
    }
    
    NSMutableArray* entries = [NSMutableArray array];
    for (NSString* fileArg in fileArgs) {
        BOOL isDir = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:fileArg isDirectory:&isDir];
        
        if (isDir) {
            [entries addObject:[SVZArchiveEntry archiveEntryWithDirectoryName:fileArg.lastPathComponent]];
            
            NSDirectoryEnumerator* etor = [[NSFileManager defaultManager] enumeratorAtPath:fileArg];
            for (NSString* path in etor) {
                NSString* fullPath = [fileArg stringByAppendingPathComponent:path];
                NSString* fullName = [fileArg.lastPathComponent stringByAppendingPathComponent:path];

                [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir];
                if (isDir) {
                    [entries addObject:[SVZArchiveEntry archiveEntryWithDirectoryName:fullName]];
                }
                else {
                    [entries addObject:[SVZArchiveEntry archiveEntryWithFileName:fullName
                                                                             url:[NSURL fileURLWithPath:fullPath]]];
                }
            }
        }
        else {
            [entries addObject:[SVZArchiveEntry archiveEntryWithFileName:fileArg.lastPathComponent
                                                                     url:[NSURL fileURLWithPath:fileArg]]];
        }
    }

    SVZArchive* archive = [SVZArchive archiveWithURL:[NSURL fileURLWithPath:archiveName]
                                     createIfMissing:YES
                                               error:NULL];
    
    return archive != nil;
}

int TestReadArchive(int argc, const char * argv[]) {
    if (argc < 2) {
        return 1;
    }

    NSString* archiveName = [NSString stringWithUTF8String:argv[1]];
    SVZArchive* archive = [SVZArchive archiveWithURL:[NSURL fileURLWithPath:archiveName]
                                     createIfMissing:NO
                                               error:NULL];
    NSLog(@"%@", archive.entries);
    
    return 0;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        return TestReadArchive(argc, argv);
    }
}
