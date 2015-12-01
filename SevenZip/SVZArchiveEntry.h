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

typedef NSInputStream* SVZ_NULLABLE_PTR (^SVZStreamBlock)(uint64_t*, NSError**);

extern SVZStreamBlock SVZStreamBlockCreateWithFileURL(NSURL* aURL);
extern SVZStreamBlock SVZStreamBlockCreateWithData(NSData* aData);


@interface SVZArchiveEntry : NSObject

@property (nonatomic, copy, readonly) NSString* name;
@property (nonatomic, assign, readonly) uint64_t compressedSize;
@property (nonatomic, assign, readonly) uint64_t uncompressedSize;
@property (nonatomic, copy, readonly) NSDate* creationDate;
@property (nonatomic, copy, readonly) NSDate* modificationDate;
@property (nonatomic, copy, readonly) NSDate* accessDate;
@property (nonatomic, assign, readonly) SVZArchiveEntryAttributes attributes;

@property (nonatomic, assign, readonly) BOOL isDirectory;
@property (nonatomic, assign, readonly) mode_t mode;

+ (SVZ_NULLABLE instancetype)archiveEntryWithFileName:(NSString*)aFileName
                                        contentsOfURL:(NSURL*)aURL;

+ (SVZ_NULLABLE instancetype)archiveEntryWithFileName:(NSString*)aFileName
                                          streamBlock:(SVZ_NULLABLE_PTR SVZStreamBlock)aStreamBlock;

+ (SVZ_NULLABLE instancetype)archiveEntryWithDirectoryName:(NSString*)aDirName;

+ (SVZ_NULLABLE instancetype)archiveEntryWithName:(NSString*)aName
                                       attributes:(SVZArchiveEntryAttributes)aAttributes
                                     creationDate:(NSDate*)aCTime
                                 modificationDate:(NSDate*)aMTime
                                       accessDate:(NSDate*)aATime
                                      streamBlock:(SVZ_NULLABLE_PTR SVZStreamBlock)aStreamBlock;

- (NSData*)newDataWithPassword:(NSString* SVZ_NULLABLE_PTR)aPassword
                         error:(NSError**)aError;

- (BOOL)extractToDirectoryAtURL:(NSURL*)aDirURL
                          error:(NSError**)aError;

@end

SVZ_ASSUME_NONNULL_END
