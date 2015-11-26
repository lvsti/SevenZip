//
//  SVZArchiveEntry.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SevenZip/SVZPreamble.h>

typedef NS_OPTIONS(uint32_t, SVZArchiveEntryAttributes) {
    // Windows file attributes
    kSVZArchiveEntryAttributeWinReadOnly = 1 << 0,
    kSVZArchiveEntryAttributeWinHidden = 1 << 1,
    kSVZArchiveEntryAttributeWinSystem = 1 << 2,
    kSVZArchiveEntryAttributeWinVolume = 1 << 3,
    kSVZArchiveEntryAttributeWinDirectory = 1 << 4,
    kSVZArchiveEntryAttributeWinArchive = 1 << 5,
    
    // UNIX permissions (see mode_t)
    kSVZArchiveEntryAttributeUnixUserR = S_IRUSR << 16,
    kSVZArchiveEntryAttributeUnixUserW = S_IWUSR << 16,
    kSVZArchiveEntryAttributeUnixUserX = S_IXUSR << 16,
    kSVZArchiveEntryAttributeUnixGroupR = S_IRGRP << 16,
    kSVZArchiveEntryAttributeUnixGroupW = S_IWGRP << 16,
    kSVZArchiveEntryAttributeUnixGroupX = S_IXGRP << 16,
    kSVZArchiveEntryAttributeUnixOtherR = S_IROTH << 16,
    kSVZArchiveEntryAttributeUnixOtherW = S_IWOTH << 16,
    kSVZArchiveEntryAttributeUnixOtherX = S_IXOTH << 16,
    kSVZArchiveEntryAttributeUnixSUID = S_ISUID << 16,
    kSVZArchiveEntryAttributeUnixSGID = S_ISGID << 16,
    kSVZArchiveEntryAttributeUnixSticky = S_ISVTX << 16,
    
    // UNIX file types (see mode_t)
    kSVZArchiveEntryAttributeUnixNamedPipe = (unsigned)S_IFIFO << 16,
    kSVZArchiveEntryAttributeUnixCharacterDevice = (unsigned)S_IFCHR << 16,
    kSVZArchiveEntryAttributeUnixDirectory = (unsigned)S_IFDIR << 16,
    kSVZArchiveEntryAttributeUnixBlockDevice = (unsigned)S_IFBLK << 16,
    kSVZArchiveEntryAttributeUnixRegularFile = (unsigned)S_IFREG << 16,
    kSVZArchiveEntryAttributeUnixSymlink = (unsigned)S_IFLNK << 16,
    kSVZArchiveEntryAttributeUnixSocket = (unsigned)S_IFSOCK << 16
};

SVZ_ASSUME_NONNULL_BEGIN

@interface SVZArchiveEntry : NSObject

@property (nonatomic, copy, readonly) NSString* name;
@property (nonatomic, assign, readonly) uint64_t compressedSize;
@property (nonatomic, assign, readonly) uint64_t uncompressedSize;
@property (nonatomic, copy, readonly) NSDate* creationDate;
@property (nonatomic, copy, readonly) NSDate* modificationDate;
@property (nonatomic, copy, readonly) NSDate* accessDate;
@property (nonatomic, assign, readonly) BOOL isDirectory;
@property (nonatomic, assign, readonly) SVZArchiveEntryAttributes attributes;
@property (nonatomic, assign, readonly) mode_t mode;

// TODO: remove this hack
@property (nonatomic, copy, readonly) NSURL* url;

+ (SVZ_NULLABLE instancetype)archiveEntryWithFileName:(NSString*)aFileName
                                                  url:(NSURL*)aFileURL;

+ (SVZ_NULLABLE instancetype)archiveEntryWithDirectoryName:(NSString*)aDirName;

- (NSData*)newDataWithPassword:(NSString* SVZ_NULLABLE_ARG)aPassword
                         error:(NSError**)aError;

- (BOOL)extractToDirectoryAtURL:(NSURL*)aDirURL
                          error:(NSError**)aError;

@end

SVZ_ASSUME_NONNULL_END
