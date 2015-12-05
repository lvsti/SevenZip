//
//  SVZArchiveEntry.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SevenZip/SVZPreamble.h>
#import <SevenZip/SVZArchiveEntryAttribute.h>

SVZ_ASSUME_NONNULL_BEGIN

/**
 * Block type for providing archive entry data
 *
 * @param aSize Pointer to the size of the data in bytes
 * @param aError Error information in case of failure. May be NULL.
 */
typedef NSInputStream* SVZ_NULLABLE_PTR (^SVZStreamBlock)(uint64_t* aSize, NSError** aError);

/**
 * Helper function to create an archive entry data provider block out of a file.
 *
 * @param aURL The file to read the data from.
 */
extern SVZStreamBlock SVZStreamBlockCreateWithFileURL(NSURL* aURL);

/**
 * Helper function to create an archive entry data provider block out of an `NSData` object.
 *
 * @param aData The data object to use as source.
 */
extern SVZStreamBlock SVZStreamBlockCreateWithData(NSData* aData);


/**
 * Class representing an entry in an `SVZArchive`.
 */
@interface SVZArchiveEntry : NSObject

/**
 * Entry name.
 *
 * Note that the name contains the full path relative to the archive root,
 * i.e. for a `dummy.txt` file located in an `example` folder within the archive
 * the value will be `example/dummy.txt`.
 */
@property (nonatomic, copy, readonly) NSString* name;

/// Compressed size in bytes (0 for new entries)
@property (nonatomic, assign, readonly) uint64_t compressedSize;

/// Uncompressed size in bytes
@property (nonatomic, assign, readonly) uint64_t uncompressedSize;

/// Creation date (aka. "ctime") of the original file
@property (nonatomic, copy, readonly) NSDate* creationDate;

/// Last modification date (aka. "mtime") of the original file
@property (nonatomic, copy, readonly) NSDate* modificationDate;

/// Last access date (aka. "atime") of the original file
@property (nonatomic, copy, readonly) NSDate* accessDate;

/// Filesystem attributes of the original file
@property (nonatomic, assign, readonly) SVZArchiveEntryAttributes attributes;


/// Indicates if this entry is a directory
@property (nonatomic, assign, readonly) BOOL isDirectory;

/// Convenience accessor for the UNIX file attributes (for files added on other systems the value is undefined)
@property (nonatomic, assign, readonly) mode_t mode;


/**
 * Creates a new file entry from the file at the specified URL.
 *
 * @param aFileName The name of the file entry (see remarks for `name`)
 * @param aURL The URL of the file to use as data source.
 *
 * @return An initialized archive entry, or nil on failure.
 */
+ (SVZ_NULLABLE instancetype)archiveEntryWithFileName:(NSString*)aFileName
                                        contentsOfURL:(NSURL*)aURL;

/**
 * Creates a new file entry with the given stream block.
 *
 * Note: if you are returning a file stream from the stream block, consider 
 * using `archiveEntryWithFileName:contentsOfURL:` instead in order to
 * preserve the original file attributes.
 *
 * @param aFileName The name of the file entry (see remarks for `name`)
 * @param aStreamBlock Data stream provider block. Pass nil for 0-byte entries.
 *
 * @return An initialized archive entry, or nil on failure.
 */
+ (SVZ_NULLABLE instancetype)archiveEntryWithFileName:(NSString*)aFileName
                                          streamBlock:(SVZStreamBlock SVZ_NULLABLE_PTR)aStreamBlock;

/**
 * Creates a new directory entry.
 *
 * @param aDirName The name of the directory entry (see remarks for `name`)
 *
 * @return An initialized archive entry, or nil on failure.
 */
+ (SVZ_NULLABLE instancetype)archiveEntryWithDirectoryName:(NSString*)aDirName;

/**
 * Creates a new archive entry.
 *
 * @param aName The name of the file/directory entry (see remarks for `name`)
 * @param aAttributes The file attributes for this entry
 * @param aCTime File creation date. Pass nil for the current time.
 * @param aMTime File modification date. Pass nil for the current time.
 * @param aCTime File access date. Pass nil for the current time.
 * @param aStreamBlock Data stream provider block. Pass nil for 0-byte entries.
 *
 * @return An initialized archive entry, or nil on failure.
 */
+ (SVZ_NULLABLE instancetype)archiveEntryWithName:(NSString*)aName
                                       attributes:(SVZArchiveEntryAttributes)aAttributes
                                     creationDate:(NSDate* SVZ_NULLABLE_PTR)aCTime
                                 modificationDate:(NSDate* SVZ_NULLABLE_PTR)aMTime
                                       accessDate:(NSDate* SVZ_NULLABLE_PTR)aATime
                                      streamBlock:(SVZStreamBlock SVZ_NULLABLE_PTR)aStreamBlock;

/**
 * Extracts the archive entry data.
 *
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return The extracted data, or nil for new entries, directories, and in case of failure.
 */
- (SVZ_NULLABLE NSData*)extractedData:(NSError**)aError;

/**
 * Extracts the archive entry data.
 *
 * @param aPassword A password for when the archive is password protected. May be nil.
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return The extracted data, or nil for new entries, directories, and in case of failure.
 */
- (SVZ_NULLABLE NSData*)extractedDataWithPassword:(NSString* SVZ_NULLABLE_PTR)aPassword
                                            error:(NSError**)aError;

/**
 * Extracts the archive entry data at the given URL.
 *
 * @param aDirURL The URL of the directory this entry should be extracted to.
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return YES on success, NO otherwise.
 */
- (BOOL)extractToDirectoryAtURL:(NSURL*)aDirURL
                          error:(NSError**)aError;

/**
 * Extracts the archive entry data at the given URL.
 *
 * @param aDirURL The URL of the directory this entry should be extracted to.
 * @param aPassword A password for when the archive is password protected. May be nil.
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return YES on success, NO otherwise.
 */
- (BOOL)extractToDirectoryAtURL:(NSURL*)aDirURL
                   withPassword:(NSString* SVZ_NULLABLE_PTR)aPassword
                          error:(NSError**)aError;

/**
 * Extracts the archive entry data to the given stream.
 *
 * @param aOutputStream The output stream to write the data into.
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return YES on success, NO otherwise.
 */
- (BOOL)extractToStream:(NSOutputStream*)aOutputStream
                  error:(NSError**)aError;

/**
 * Extracts the archive entry data to the given stream.
 *
 * @param aOutputStream The output stream to write the data into.
 * @param aPassword A password for when the archive is password protected. May be nil.
 * @param aError Error information in case of failure. May be NULL.
 *
 * @return YES on success, NO otherwise.
 */
- (BOOL)extractToStream:(NSOutputStream*)aOutputStream
           withPassword:(NSString* SVZ_NULLABLE_PTR)aPassword
                  error:(NSError**)aError;

@end

SVZ_ASSUME_NONNULL_END
