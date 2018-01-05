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

/// Compression level for archive update operations (higher is slower)
typedef NS_ENUM(NSUInteger, SVZCompressionLevel) {
    /// no compression, copy only
    kSVZCompressionLevelNone = 0,
    
    //  (Method, Dictionary, FastBytes, MatchFinder, Filter)
    /// LZMA2, 64 KB, 32, HC4, BCJ
    kSVZCompressionLevelLowest,
    
    /// LZMA2, 1 MB, 32, HC4, BCJ
    kSVZCompressionLevelLow,
    
    /// LZMA2, 16 MB, 32, BT4, BCJ
    kSVZCompressionLevelNormal,

    /// LZMA2, 32 MB, 64, BT4, BCJ
    kSVZCompressionLevelHigh,

    /// LZMA2, 64 MB, 64, BT4, BCJ2
    kSVZCompressionLevelHighest
};

/**
 * Class representing a 7-zip archive file.
 */
@interface SVZArchive : NSObject

/// The (future) URL of the file backing this archive
@property (nonatomic, copy, readonly) NSURL* url;

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
 * This method can only be used to open existing archives. To create a new archive,
 * use `archiveWithURL:createIfMissing:error:`.
 *
 * @param aURL The location of the 7-zip archive to be created at/read from.
 * @param aPassword The password to use for opening the archive (typically when 
 *                  header encryption is enabled). May be nil.
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return An initialized archive object, or nil in case of any failure.
 */
+ (SVZ_NULLABLE instancetype)archiveWithURL:(NSURL*)aURL
                                   password:(NSString* SVZ_NULLABLE_PTR)aPassword
                                      error:(NSError**)aError;

/**
 * Commits the given entries to the file backing this archive.
 *
 * This method replaces ALL current entries in the receiver with the ones in `aEntries`.
 * To update only part of the archive, make a mutable copy of the `entries` property, apply
 * the necessary changes, then pass it back to this method.
 *
 * NOTE: If the archive previously had header encryption, calling this method will disable it.
 * To preserve header encryption, use `updateEntries:withPassword:headerEncryption:error:`.
 *
 * @param aEntries The entries that should be written to the archive file.
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return YES on success, otherwise NO.
 */
- (BOOL)updateEntries:(SVZ_GENERIC(NSArray, SVZArchiveEntry*)*)aEntries
                error:(NSError**)aError;

/**
 * Commits the given entries to the file backing this archive.
 *
 * This method replaces ALL current entries in the receiver with the ones in `aEntries`.
 * To update only part of the archive, make a mutable copy of the `entries` property, apply
 * the necessary changes, then pass it back to this method.
 *
 * NOTE: Due to the peculiarities of the 7-zip archive, it is possible to create an archive
 * which uses different passwords for each of its contained entries. This method only applies
 * the provided password for encrypting newly added entries. If you are updating
 * an archive that already contained some files, those entries will not be re-encrypted
 * with the new password. If you still needed that behavior, you'd have to manually extract 
 * and re-add existing entries.
 *
 * WARNING: Setting header encryption with password X for an existing archive whose
 * entries are encrypted with a different password Y can cause trouble in some 7-zip clients,
 * so this awkward combination is best to be avoided.
 *
 * @param aEntries The entries that should be written to the archive file.
 * @param aPassword The password to use for encryption (optional). If nil, no encryption is applied.
 * @param aUseHeaderEncryption Controls header encryption when a password is provided, as follows:
 *              If set to NO, only the newly added archive entries will be encrypted,
 *              which means extracting these entries will require the password given in `aPassword`.
 *              If set to YES, both the newly added entries AND the archive header will be encrypted,
 *              which means both listing the archive contents and extracting these entries will require 
 *              the password given in `aPassword`.
 *              If `aPassword` is empty, this flag is ignored.
 * @param aCompressionLevel Compression level to use
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return YES on success, otherwise NO.
 */
- (BOOL)updateEntries:(SVZ_GENERIC(NSArray, SVZArchiveEntry*)*)aEntries
         withPassword:(NSString* SVZ_NULLABLE_PTR)aPassword
     headerEncryption:(BOOL)aUseHeaderEncryption
     compressionLevel:(SVZCompressionLevel)aCompressionLevel
                error:(NSError**)aError;

@end

SVZ_ASSUME_NONNULL_END
