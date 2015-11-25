//
//  SVZStoredArchiveEntry.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "SVZArchiveEntry.h"

@class SVZArchive;

SVZ_ASSUME_NONNULL_BEGIN

@interface SVZStoredArchiveEntry : SVZArchiveEntry

@property (nonatomic, assign, readonly) NSUInteger index;
@property (nonatomic, weak, readonly) SVZArchive* archive;

- (SVZ_NULLABLE instancetype)initWithIndex:(NSUInteger)aIndex
                                 inArchive:(SVZArchive*)aArchive;

- (void)invalidate;

@end

SVZ_ASSUME_NONNULL_END
