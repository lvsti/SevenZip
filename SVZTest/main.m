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
                                                                   contentsOfURL:[NSURL fileURLWithPath:fullPath]]];
                }
            }
        }
        else {
            [entries addObject:[SVZArchiveEntry archiveEntryWithFileName:fileArg.lastPathComponent
                                                           contentsOfURL:[NSURL fileURLWithPath:fileArg]]];
        }
    }

    SVZArchive* archive = [SVZArchive archiveWithURL:[NSURL fileURLWithPath:archiveName]
                                     createIfMissing:YES
                                               error:NULL];
    if (!archive) {
        return 1;
    }
    
    return ![archive updateEntries:entries error:NULL];
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

int TestExtractToMemory(int argc, const char * argv[]) {
    if (argc < 2) {
        return 1;
    }
    
    NSString* archiveName = [NSString stringWithUTF8String:argv[1]];
    SVZArchive* archive = [SVZArchive archiveWithURL:[NSURL fileURLWithPath:archiveName]
                                     createIfMissing:NO
                                               error:NULL];
    SVZArchiveEntry* entry = archive.entries.firstObject;
    NSData* data = [entry newDataWithPassword:nil error:NULL];
    NSLog(@"data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    return 0;
}

int TestExtractToFile(int argc, const char * argv[]) {
    if (argc < 2) {
        return 1;
    }
    
    NSString* archiveName = [NSString stringWithUTF8String:argv[1]];
    SVZArchive* archive = [SVZArchive archiveWithURL:[NSURL fileURLWithPath:archiveName]
                                     createIfMissing:NO
                                               error:NULL];
    SVZArchiveEntry* entry = archive.entries.firstObject;
    BOOL success = [entry extractToDirectoryAtURL:[NSURL fileURLWithPath:@"/Users/lvsti/x"]
                                            error:NULL];
    return success? 0: 1;
}

int TestUpdateArchive(int argc, const char* argv[]) {
    if (argc < 2) {
        return 1;
    }
    
    NSString* archiveName = [NSString stringWithUTF8String:argv[1]];
    SVZArchive* archive = [SVZArchive archiveWithURL:[NSURL fileURLWithPath:archiveName]
                                     createIfMissing:NO
                                               error:NULL];
    if (!archive) {
        return 1;
    }
    
    NSMutableArray* entries = [archive.entries mutableCopy];
    [entries removeObjectAtIndex:0];
    [entries addObject:[SVZArchiveEntry archiveEntryWithFileName:@"stuff.txt"
                                                   contentsOfURL:[NSURL fileURLWithPath:@"/Users/lvsti/stuff.txt"]]];
    if (![archive updateEntries:entries error:NULL]) {
        return 1;
    }
    
    return 0;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
//        return TestCreateArchive(argc, argv);
//        return TestReadArchive(argc, argv);
//        return TestExtractToMemory(argc, argv);
//        return TestExtractToFile(argc, argv);
        return TestUpdateArchive(argc, argv);
    }
}
