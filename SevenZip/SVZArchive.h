//
//  SVZArchive.h
//  ObjC7z
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SVZArchiveEntry;

@interface SVZArchive : NSObject

@property (nonatomic, copy, readonly) NSURL* url;

+ (nullable instancetype)archiveWithURL:(NSURL*)url
                                  error:(NSError**)error;

@property (nonatomic, copy, readonly) NSArray<SVZArchiveEntry*>* entries;

- (BOOL)updateEntries:(NSArray<SVZArchiveEntry*>*)entries
                error:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
