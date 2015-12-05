//
//  SVZArchiveEntry.m
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "SVZArchiveEntry.h"
#import "SVZArchiveEntry_Private.h"

static const uint64_t kSVZInvalidSize = ~0;

static const SVZArchiveEntryAttributes kSVZDefaultFileAttributes =
    kSVZArchiveEntryAttributeUnixRegularFile |
    kSVZArchiveEntryAttributeUnixUserR |
    kSVZArchiveEntryAttributeUnixUserW |
    kSVZArchiveEntryAttributeUnixGroupR |
    kSVZArchiveEntryAttributeUnixOtherR;

static const SVZArchiveEntryAttributes kSVZDefaultDirectoryAttributes =
    kSVZArchiveEntryAttributeUnixDirectory |
    kSVZArchiveEntryAttributeUnixUserR |
    kSVZArchiveEntryAttributeUnixUserW |
    kSVZArchiveEntryAttributeUnixUserX |
    kSVZArchiveEntryAttributeUnixGroupR |
    kSVZArchiveEntryAttributeUnixGroupX |
    kSVZArchiveEntryAttributeUnixOtherR |
    kSVZArchiveEntryAttributeUnixOtherX;

SVZStreamBlock SVZStreamBlockCreateWithFileURL(NSURL* aURL) {
    NSCAssert([aURL isFileURL], @"url must point to a local file");
    return ^NSInputStream*(unsigned long long* size, NSError** error) {
        NSNumber* sizeValue = nil;
        if (![aURL getResourceValue:&sizeValue forKey:NSURLFileSizeKey error:error]) {
            return nil;
        }
        
        *size = sizeValue.unsignedLongLongValue;
        return [NSInputStream inputStreamWithURL:aURL];
    };
}

SVZStreamBlock SVZStreamBlockCreateWithData(NSData* aData) {
    NSCParameterAssert(aData);
    return ^NSInputStream*(unsigned long long* size, NSError** error) {
        *size = aData.length;
        return [NSInputStream inputStreamWithData:aData];
    };
}

@implementation SVZArchiveEntry

+ (instancetype)archiveEntryWithFileName:(NSString*)aFileName
                           contentsOfURL:(NSURL*)aURL {
    NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:aURL.path
                                                                                error:NULL];
    if (!attributes) {
        return nil;
    }

    return [[self alloc] initWithName:aFileName
                           attributes:[attributes[NSFilePosixPermissions] unsignedIntValue] << 16
                         creationDate:attributes[NSFileCreationDate]
                     modificationDate:attributes[NSFileModificationDate]
                           accessDate:[NSDate date]
                          streamBlock:SVZStreamBlockCreateWithFileURL(aURL)];
}

+ (instancetype)archiveEntryWithFileName:(NSString*)aFileName
                             streamBlock:(SVZStreamBlock)aStreamBlock {
    return [[self alloc] initWithName:aFileName
                           attributes:kSVZDefaultFileAttributes
                         creationDate:[NSDate date]
                     modificationDate:[NSDate date]
                           accessDate:[NSDate date]
                          streamBlock:aStreamBlock];
}

+ (instancetype)archiveEntryWithDirectoryName:(NSString*)aDirName {
    return [[self alloc] initWithName:aDirName
                           attributes:kSVZDefaultDirectoryAttributes
                         creationDate:[NSDate date]
                     modificationDate:[NSDate date]
                           accessDate:[NSDate date]
                          streamBlock:nil];
}

+ (instancetype)archiveEntryWithName:(NSString*)aName
                          attributes:(SVZArchiveEntryAttributes)aAttributes
                        creationDate:(NSDate*)aCTime
                    modificationDate:(NSDate*)aMTime
                          accessDate:(NSDate*)aATime
                         streamBlock:(SVZStreamBlock)aStreamBlock {
    NSDate* now = [NSDate date];
    return [[self alloc] initWithName:aName
                           attributes:aAttributes
                         creationDate:aCTime ?: now
                     modificationDate:aMTime ?: now
                           accessDate:aATime ?: now
                          streamBlock:aStreamBlock];
}

- (instancetype)initWithName:(NSString*)aName
                  attributes:(SVZArchiveEntryAttributes)aAttributes
                creationDate:(NSDate*)aCTime
            modificationDate:(NSDate*)aMTime
                  accessDate:(NSDate*)aATime
                 streamBlock:(SVZStreamBlock)aStreamBlock {
    NSParameterAssert(aName);
    NSParameterAssert(aCTime);
    NSParameterAssert(aMTime);
    NSParameterAssert(aATime);
    
    uint64_t dataSize = 0;
    NSInputStream* dataStream = nil;
    
    if (aStreamBlock) {
        NSError* error = nil;
        dataSize = kSVZInvalidSize;
        dataStream = aStreamBlock(&dataSize, &error);
        NSAssert(dataStream, @"returned stream must not be nil, consider nilling out the block instead");
        NSAssert(dataSize != kSVZInvalidSize, @"size of the streamed data must be provided");
    }

    self = [super init];
    if (self) {
        _name = [aName copy];
        _attributes = aAttributes;
        _creationDate = aCTime;
        _modificationDate = aMTime;
        _accessDate = aATime;
        _uncompressedSize = dataSize;
        _dataStream = dataStream;
    }
    
    return self;
}

- (BOOL)isDirectory {
    return self.attributes & kSVZArchiveEntryAttributeWinDirectory ||
           self.attributes & kSVZArchiveEntryAttributeUnixDirectory;
}

- (mode_t)mode {
    return self.attributes >> 16;
}

- (NSData*)extractedData:(NSError**)aError {
    return [self extractedDataWithPassword:nil error:aError];
}

- (NSData*)extractedDataWithPassword:(NSString*)aPassword
                               error:(NSError**)aError {
    NSOutputStream* memoryStream = [NSOutputStream outputStreamToMemory];
    if (![self extractToStream:memoryStream
                  withPassword:aPassword
                         error:aError]) {
        return nil;
    }
    
    NSData* data = [memoryStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    return data;
}

- (BOOL)extractToDirectoryAtURL:(NSURL*)aDirURL
                          error:(NSError**)aError {
    return [self extractToDirectoryAtURL:aDirURL
                            withPassword:nil
                                   error:aError];
}

- (BOOL)extractToDirectoryAtURL:(NSURL*)aDirURL
                   withPassword:(NSString*)aPassword
                          error:(NSError**)aError {
    NSURL* entryURL = [aDirURL URLByAppendingPathComponent:self.name];
    if (![[NSFileManager defaultManager] createDirectoryAtURL:entryURL.URLByDeletingLastPathComponent
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:aError]) {
        return NO;
    }
    
    NSOutputStream* fileStream = [NSOutputStream outputStreamWithURL:entryURL append:NO];
    return [self extractToStream:fileStream
                    withPassword:aPassword
                           error:aError];
}

- (BOOL)extractToStream:(NSOutputStream*)aOutputStream
                  error:(NSError**)aError {
    return [self extractToStream:aOutputStream
                    withPassword:nil
                           error:aError];
}

- (BOOL)extractToStream:(NSOutputStream*)aOutputStream
           withPassword:(NSString*)aPassword
                  error:(NSError**)aError {
    return NO;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@:%p> kind:%@ path:%@%@",
            [self class],
            self,
            self.isDirectory? @"DIR": @"FILE",
            self.name,
            self.isDirectory? @"": [NSString stringWithFormat:@" size:%lld", self.uncompressedSize]];
}

@end
