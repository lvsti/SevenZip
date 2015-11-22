//
//  SVZArchiveEntry.m
//  ObjC7z
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "SVZArchiveEntry.h"

@implementation SVZArchiveEntry

+ (instancetype)archiveEntryWithFileName:(NSString*)aFileName
                                     url:(NSURL*)aFileURL {
    return [[self alloc] initWithName:aFileName
                                  url:aFileURL];
}

- (instancetype)initWithName:(NSString*)aFileName
                         url:(NSURL* _Nullable)aFileURL {
    NSParameterAssert(aFileName);
    NSAssert(!aFileURL || [aFileURL isFileURL], @"fileURL must point to a local file");
    
    self = [super init];
    if (self) {
        _name = [aFileName copy];
        _url = [aFileURL copy];
        _attributes = aFileURL? 0: kSVZArchiveEntryAttributeWinDirectory;
        
        if (self.isDirectory) {
            _creationDate = [NSDate date];
            _modificationDate = _creationDate;
            _accessDate = _creationDate;
        }
        else {
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.url.path
                                                                                        error:NULL];
            if (!attributes) {
                self = nil;
                return self;
            }
            
            _uncompressedSize = [attributes[NSFileSize] unsignedIntegerValue];
            _creationDate = attributes[NSFileCreationDate];
            _modificationDate = attributes[NSFileModificationDate];
            _accessDate = attributes[NSFileModificationDate];
            _attributes |= [attributes[NSFilePosixPermissions] unsignedIntValue] << 16;
        }
    }
    return self;
}

+ (instancetype)archiveEntryWithDirectoryName:(NSString*)aDirName {
    return [[self alloc] initWithName:aDirName
                                  url:nil];
}

- (BOOL)isDirectory {
    return self.attributes & kSVZArchiveEntryAttributeWinDirectory;
}

@end
