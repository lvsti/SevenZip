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


@interface SVZArchive : NSObject

@property (nonatomic, copy, readonly) NSURL* url;

+ (SVZ_NULLABLE instancetype)archiveWithURL:(NSURL*)aURL
                            createIfMissing:(BOOL)aShouldCreate
                                      error:(NSError**)aError;

@property (nonatomic, copy, readonly) SVZ_GENERIC(NSArray, SVZArchiveEntry*)* entries;

- (BOOL)updateEntries:(SVZ_GENERIC(NSArray, SVZArchiveEntry*)*)aEntries
                error:(NSError**)aError;

@end

SVZ_ASSUME_NONNULL_END
