//
//  SVZArchiveEntry.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(uint32_t, SVZArchiveEntryAttributes) {
    kSVZArchiveEntryAttributeWinReadOnly = 1 << 0,
    kSVZArchiveEntryAttributeWinHidden = 1 << 1,
    kSVZArchiveEntryAttributeWinSystem = 1 << 2,
    kSVZArchiveEntryAttributeWinDirectory = 1 << 4,
    kSVZArchiveEntryAttributeWinArchive = 1 << 5
};

NS_ASSUME_NONNULL_BEGIN

@interface SVZArchiveEntry : NSObject

@property (nonatomic, copy, readonly) NSString* name;
@property (nonatomic, assign, readonly) size_t compressedSize;
@property (nonatomic, assign, readonly) size_t uncompressedSize;
@property (nonatomic, copy, readonly) NSDate* creationDate;
@property (nonatomic, copy, readonly) NSDate* modificationDate;
@property (nonatomic, copy, readonly) NSDate* accessDate;
@property (nonatomic, assign, readonly) BOOL isDirectory;
@property (nonatomic, assign, readonly) SVZArchiveEntryAttributes attributes;

// TODO: remove this hack
@property (nonatomic, copy, readonly) NSURL* url;

+ (nullable instancetype)archiveEntryWithFileName:(NSString*)aFileName
                                              url:(NSURL*)aFileURL;

+ (nullable instancetype)archiveEntryWithDirectoryName:(NSString*)aDirName;

@end

NS_ASSUME_NONNULL_END
