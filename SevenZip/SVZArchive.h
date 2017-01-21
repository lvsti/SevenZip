//
//  SVZArchive.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SevenZip/SVZPreamble.h>

SVZ_ASSUME_NONNULL_BEGIN

@class SVZArchiveEntry;

extern NSString* const kSVZArchiveErrorDomain;

typedef NS_ENUM(NSInteger, SVZArchiveError) {
    kSVZArchiveErrorFileNotFound = -1,
    kSVZArchiveErrorInvalidArchive = -2,
    kSVZArchiveErrorFileOpenFailed = -3,
    kSVZArchiveErrorFileCreateFailed = -4,
    kSVZArchiveErrorUpdateFailed = -5,
    kSVZArchiveErrorForeignEntry = -6
};


/**
 * Class representing a 7-zip archive file.
 */
@interface SVZArchive : NSObject

/// The (future) URL of the file backing this archive
@property (nonatomic, copy, readonly) NSURL* url;

/// The password used for encryption.
/// If non-nil, encryption is enabled, otherwise encryption is disabled.
@property (nonatomic, copy, SVZ_NULLABLE) NSString* password;

/// Indicates whether the archive uses header encryption when encryption is enabled.
/// When set to YES, listing the archive contents also requires password.
@property (nonatomic, assign) BOOL usesHeaderEncryption;

/// The entries within this archive.
@property (nonatomic, copy, readonly) SVZ_GENERIC(NSArray, SVZArchiveEntry*)* entries;

/**
 * Opens a 7-zip archive with the given URL.
 *
 * If the file specified by the URL already exists, it is assumed to be a 7-zip archive 
 * and is subsequently opened.
 * If there is no file at the given URL, a new archive object is created in memory 
 * if the `aShouldCreate` flag is set.
 *
 * @param aURL The location of the 7-zip archive to be created at/read from.
 * @param aShouldCreate If set, a new archive is created when `aURL` doesn't point to an existing entry.
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return An initialized archive object, or nil in case of any failure.
 */
+ (SVZ_NULLABLE instancetype)archiveWithURL:(NSURL*)aURL
                            createIfMissing:(BOOL)aShouldCreate
                                      error:(NSError**)aError;

/**
 * Opens a 7-zip archive with the given URL.
 *
 * If the file specified by the URL already exists, it is assumed to be a 7-zip archive 
 * and is subsequently opened.
 * If there is no file at the given URL, a new archive object is created in memory 
 * if the `aShouldCreate` flag is set.
 *
 * @param aURL The location of the 7-zip archive to be created at/read from.
 * @param aPassword The password used for encryption. May be nil.
 * @param aShouldCreate If set, a new archive is created when `aURL` doesn't point to an existing entry.
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return An initialized archive object, or nil in case of any failure.
 */
+ (SVZ_NULLABLE instancetype)archiveWithURL:(NSURL*)aURL
                                   password:(NSString* SVZ_NULLABLE_PTR)aPassword
                            createIfMissing:(BOOL)aShouldCreate
                                      error:(NSError**)aError;

/**
 * Commits the given entries to the file backing this archive.
 *
 * This method replaces ALL current entries in the receiver with the ones in `aEntries`.
 * To update only part of the archive, make a mutable copy of the `entries` property, apply
 * the necessary changes, then pass it back to this method.
 *
 * @param aEntries The entries that should be written to the archive file.
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return YES on success, otherwise NO.
 */
- (BOOL)updateEntries:(SVZ_GENERIC(NSArray, SVZArchiveEntry*)*)aEntries
                error:(NSError**)aError;

@end

SVZ_ASSUME_NONNULL_END
