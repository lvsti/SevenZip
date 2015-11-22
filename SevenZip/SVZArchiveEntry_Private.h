//
//  SVZArchiveEntry_Private.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <SevenZip/SevenZip.h>

@interface SVZArchiveEntry ()

@property (nonatomic, copy, readwrite) NSString* name;
@property (nonatomic, assign, readwrite) uint64_t compressedSize;
@property (nonatomic, assign, readwrite) uint64_t uncompressedSize;
@property (nonatomic, copy, readwrite) NSDate* creationDate;
@property (nonatomic, copy, readwrite) NSDate* modificationDate;
@property (nonatomic, copy, readwrite) NSDate* accessDate;
@property (nonatomic, assign, readwrite) SVZArchiveEntryAttributes attributes;

@end
