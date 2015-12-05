//
//  UT_SVZArchiveEntry.m
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 12. 05..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Kiwi/Kiwi.h>

#import <SevenZip/SevenZip.h>
#import "NSFileSecurity+AsIfItWere2015.h"

@interface SVZArchiveEntry (UT)
+ (NSFileManager*)fileManager;
@end


SPEC_BEGIN(ArchiveEntrySpec)

describe(@"ArchiveEntry", ^{
    __block SVZArchiveEntry* sut = nil;
    __block NSError* error = nil;
    
    context(@"stream block construction", ^{
        
        __block unsigned long long size = -1;
        __block NSInputStream* stream = nil;
        
        NSData* (^dataFromStream)(NSInputStream*) = ^NSData*(NSInputStream* stream) {
            [stream open];
            uint8_t buf[64];
            NSInteger bytesRead = [stream read:buf maxLength:64];
            [stream close];
            
            return [NSData dataWithBytes:buf length:bytesRead];
        };
        
        beforeEach(^{
            stream = nil;
            size = -1;
            error = nil;
        });

        context(@"from file", ^{
            
            __block NSURL* sourceURL = nil;
            __block NSData* data = nil;
            
            beforeEach(^{
                NSString* random = [NSUUID UUID].UUIDString;
                NSString* sourcePath = [NSTemporaryDirectory() stringByAppendingPathComponent:random];
                sourceURL = [NSURL fileURLWithPath:sourcePath];
                
                data = [@"foobar" dataUsingEncoding:NSUTF8StringEncoding];
                BOOL success = [data writeToURL:sourceURL atomically:NO];
                NSAssert(success, @"cannot prepare fixture");
            });
            
            afterEach(^{
                [[NSFileManager defaultManager] removeItemAtURL:sourceURL
                                                          error:NULL];
            });
            
            it(@"sets the expected size to the file size", ^{
                // given
                SVZStreamBlock block = SVZStreamBlockCreateWithFileURL(sourceURL);

                NSNumber* fileSize = nil;
                [sourceURL getResourceValue:&fileSize forKey:NSURLFileSizeKey
                                      error:NULL];
                NSAssert(fileSize, @"invalid fixture");
                
                // when
                block(&size, &error);
                
                // then
                [[theValue(size) should] equal:theValue(fileSize.unsignedLongLongValue)];
            });
            
            it(@"returns a stream that reads from the given file", ^{
                // given
                SVZStreamBlock block = SVZStreamBlockCreateWithFileURL(sourceURL);
                NSData* expectedData = [NSData dataWithContentsOfURL:sourceURL];

                // when
                stream = block(&size, &error);
                
                // then
                [[stream should] beKindOfClass:[NSInputStream class]];
                NSData* actualData = dataFromStream(stream);
                [[actualData should] equal:expectedData];
            });

        });
        
        context(@"from data", ^{

            __block NSData* data = nil;
            
            beforeEach(^{
                data = [@"foobar" dataUsingEncoding:NSUTF8StringEncoding];
            });

            it(@"sets the expected size to the data length", ^{
                // given
                SVZStreamBlock block = SVZStreamBlockCreateWithData(data);
                
                // when
                block(&size, &error);
                
                // then
                [[theValue(size) should] equal:theValue((unsigned long long)data.length)];
            });
            
            it(@"returns a stream that reads from the given data", ^{
                // given
                SVZStreamBlock block = SVZStreamBlockCreateWithData(data);
                
                // when
                stream = block(&size, &error);
                
                // then
                [[stream should] beKindOfClass:[NSInputStream class]];
                NSData* actualData = dataFromStream(stream);
                [[actualData should] equal:data];
            });

        });
        
    });
    
    context(@"new entry", ^{
        
        context(@"file from URL", ^{
            
            __block NSURL* fileURL = nil;
            __block NSDictionary* attributes = nil;
            
            beforeEach(^{
                attributes = @{
                    NSURLFileSecurityKey: ({
                        NSFileSecurity* fs = [NSFileSecurity new];
                        fs.mode = S_IRWXU | S_IRWXO | S_IRWXG | S_IFREG; fs;
                    }),
                    NSURLContentAccessDateKey: [NSDate dateWithTimeIntervalSinceNow:0],
                    NSURLContentModificationDateKey: [NSDate dateWithTimeIntervalSinceReferenceDate:0],
                    NSURLCreationDateKey: [NSDate dateWithTimeIntervalSince1970:0],
                    NSURLFileSizeKey: @42
                };
                
                fileURL = [NSURL mock];
                [fileURL stub:@selector(isFileURL) andReturn:theValue(YES)];
                [fileURL stub:@selector(scheme) andReturn:@"file"];
                [fileURL stub:@selector(resourceValuesForKeys:error:) andReturn:attributes];
                [fileURL stub:@selector(getResourceValue:forKey:error:) withBlock:^id(NSArray *params) {
                    id __autoreleasing* ptr = (id __autoreleasing*)[params[0] pointerValue];
                    *ptr = attributes[params[1]];
                    return theValue(YES);
                }];
            });
            
            it(@"respects the file name", ^{
                // when
                sut = [SVZArchiveEntry archiveEntryWithFileName:@"stuff.txt"
                                                  contentsOfURL:fileURL];
                
                // then
                [[sut.name should] equal:@"stuff.txt"];
            });
            
            it(@"reads and uses the file attributes", ^{
                // when
                sut = [SVZArchiveEntry archiveEntryWithFileName:@"stuff.txt"
                                                  contentsOfURL:fileURL];
                
                // then
                [[theValue(sut.mode) should] equal:theValue([(NSFileSecurity*)attributes[NSURLFileSecurityKey] mode])];
                [[sut.creationDate should] equal:attributes[NSURLCreationDateKey]];
                [[sut.modificationDate should] equal:attributes[NSURLContentModificationDateKey]];
                [[sut.accessDate should] equal:attributes[NSURLContentAccessDateKey]];
                [[theValue(sut.uncompressedSize) should] equal:attributes[NSURLFileSizeKey]];
            });
            
            it(@"returns with error if the attributes cannot be read", ^{
                // given
                [fileURL stub:@selector(resourceValuesForKeys:error:) andReturn:nil];
                
                // when
                sut = [SVZArchiveEntry archiveEntryWithFileName:@"stuff.txt"
                                                  contentsOfURL:fileURL];
                
                // then
                [[sut should] beNil];
            });
            
        });
        
        context(@"file from stream block", ^{
            
            it(@"respects the file name", ^{
                // when
                sut = [SVZArchiveEntry archiveEntryWithFileName:@"stuff.txt"
                                                    streamBlock:nil];
                
                // then
                [[sut.name should] equal:@"stuff.txt"];
            });
            
            it(@"calls the stream block at initialization and sets the size accordingly", ^{
                // given
                __block BOOL didCall = NO;
                SVZStreamBlock block = ^NSInputStream*(uint64_t* aSize, NSError** aError) {
                    didCall = YES;
                    *aSize = 42;
                    return [NSInputStream inputStreamWithData:[NSData data]];
                };
                
                // when
                sut = [SVZArchiveEntry archiveEntryWithFileName:@"stuff.txt"
                                                    streamBlock:block];
                
                // then
                [[theValue(didCall) should] beYes];
                [[theValue(sut.uncompressedSize) should] equal:theValue(42)];
            });
            
            it(@"sets default attributes", ^{
                // when
                sut = [SVZArchiveEntry archiveEntryWithFileName:@"stuff.txt"
                                                    streamBlock:nil];
                
                // then
                [[theValue(sut.mode) should] equal:theValue((mode_t)S_IFREG | 0644)];
                [[theValue([sut.creationDate timeIntervalSinceNow]) should] beLessThan:theValue(1.0)];
                [[sut.modificationDate should] equal:sut.creationDate];
                [[sut.accessDate should] equal:sut.creationDate];
            });
            
            it(@"doesn't open the stream", ^{
                // given
                NSInputStream* streamMock = [NSInputStream mock];
                SVZStreamBlock block = ^NSInputStream*(uint64_t* aSize, NSError** aError) {
                    *aSize = 0;
                    return streamMock;
                };
                
                // then
                [[streamMock shouldNot] receive:@selector(open)];

                // when
                sut = [SVZArchiveEntry archiveEntryWithFileName:@"stuff.txt"
                                                    streamBlock:block];
            });
            
        });
        
        context(@"directory", ^{
            
            it(@"respects the file name", ^{
                // when
                sut = [SVZArchiveEntry archiveEntryWithDirectoryName:@"foobar"];
                
                // then
                [[sut.name should] equal:@"foobar"];
            });

            it(@"sets default attributes", ^{
                // when
                sut = [SVZArchiveEntry archiveEntryWithDirectoryName:@"foobar"];
                
                // then
                [[theValue(sut.mode) should] equal:theValue((mode_t)S_IFDIR | 0755)];
                [[theValue([sut.creationDate timeIntervalSinceNow]) should] beLessThan:theValue(1.0)];
                [[sut.modificationDate should] equal:sut.creationDate];
                [[sut.accessDate should] equal:sut.creationDate];
            });

        });
        
        context(@"fully custom", ^{
            
            it(@"takes whatever is provided", ^{
                // given
                SVZStreamBlock block = ^NSInputStream*(uint64_t* aSize, NSError** aError) {
                    *aSize = 42;
                    return [NSInputStream inputStreamWithData:[NSData data]];
                };
                NSDate* ctime = [NSDate dateWithTimeIntervalSince1970:0];
                NSDate* mtime = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
                NSDate* atime = [NSDate date];

                // when
                sut = [SVZArchiveEntry archiveEntryWithName:@"foobar"
                                                 attributes:0xbaadbeef
                                               creationDate:ctime
                                           modificationDate:mtime
                                                 accessDate:atime
                                                streamBlock:block];
                
                // then
                [[sut.name should] equal:@"foobar"];
                [[sut.creationDate should] equal:ctime];
                [[sut.modificationDate should] equal:mtime];
                [[sut.accessDate should] equal:atime];
                [[theValue(sut.attributes) should] equal:theValue(0xbaadbeef)];
                [[theValue(sut.uncompressedSize) should] equal:theValue(42)];
            });
            
        });
        
    });
    
    context(@"stored entry", ^{
        
        __block SVZArchive* archive = nil;
        
        NSURL* (^fixtureNamed)(NSString*) = ^NSURL*(NSString* name) {
            return [[NSBundle bundleForClass:self] URLForResource:name withExtension:@"7z"];
        };
        
        context(@"metadata", ^{

            beforeEach(^{
                archive = [SVZArchive archiveWithURL:fixtureNamed(@"basic")
                                     createIfMissing:NO
                                               error:&error];
                NSAssert(archive, @"fixture not found");
            });
            
            it(@"properly exposes all attributes", ^{
                // when
                static const double kUNIXToWindowsEpochDelta = -11644473600;
                sut = archive.entries.firstObject;
                
                // then
                [[sut.name should] equal:@"stuff.txt"];
                [[theValue(sut.uncompressedSize) should] equal:theValue(6)];
                [[theValue(sut.compressedSize) should] equal:theValue(11)];
                [[theValue([sut.creationDate timeIntervalSince1970]) should] equal:theValue(kUNIXToWindowsEpochDelta)];
                [[theValue([sut.accessDate timeIntervalSince1970]) should] equal:theValue(kUNIXToWindowsEpochDelta)];
                [[theValue([sut.modificationDate timeIntervalSince1970]) should] equal:theValue(1448131943)];
                [[theValue(sut.attributes) should] equal:theValue(0x81a48020)];
            });
            
        });
        
        context(@"extracting files", ^{
            
            __block NSData* entryData = nil;
            
            beforeEach(^{
                // given
                entryData = [@"stuff\n" dataUsingEncoding:NSUTF8StringEncoding];
                archive = [SVZArchive archiveWithURL:fixtureNamed(@"basic")
                                     createIfMissing:NO
                                               error:&error];
                NSAssert(archive, @"fixture not found");
                
                sut = archive.entries.firstObject;
            });
            
            it(@"extracts to memory", ^{
                // when
                NSData* data = [sut extractedData:&error];
                
                // then
                [[data should] equal:entryData];
            });
            
            it(@"extracts to disk", ^{
                // given
                NSURL* dirURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
                NSURL* targetURL = [dirURL URLByAppendingPathComponent:sut.name];
                [[NSFileManager defaultManager] removeItemAtURL:targetURL
                                                          error:NULL];
                
                // when
                BOOL success = [sut extractToDirectoryAtURL:dirURL error:&error];
                
                // then
                [[theValue(success) should] beYes];
                NSData* actualData = [NSData dataWithContentsOfURL:targetURL];
                [[actualData should] equal:entryData];
                
                [[NSFileManager defaultManager] removeItemAtURL:targetURL
                                                          error:NULL];
            });
            
            it(@"extracts to stream", ^{
                // given
                NSOutputStream* stream = [NSOutputStream outputStreamToMemory];
                
                // when
                BOOL success = [sut extractToStream:stream
                                              error:&error];
                
                // then
                [[theValue(success) should] beYes];
                NSData* actualData = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
                [[actualData should] equal:entryData];
            });
            
        });
        
        context(@"extracting password-protected files", ^{

            NSString* validPassword = @"secret";
            NSString* invalidPassword = @"wrong";
            __block NSData* entryData = nil;
            
            beforeEach(^{
                // given
                entryData = [@"stuff\n" dataUsingEncoding:NSUTF8StringEncoding];
                archive = [SVZArchive archiveWithURL:fixtureNamed(@"protected")
                                     createIfMissing:NO
                                               error:&error];
                NSAssert(archive, @"fixture not found");
                
                sut = archive.entries.firstObject;
            });

            context(@"to memory", ^{

                it(@"extracts to memory", ^{
                    // when
                    NSData* data = [sut extractedDataWithPassword:validPassword error:&error];
                    
                    // then
                    [[data should] equal:entryData];
                });
                
                it(@"fails to extract to memory if password is invalid", ^{
                    // when
                    NSData* data = [sut extractedDataWithPassword:invalidPassword error:&error];
                    
                    // then
                    [[data should] beNil];
                });
                
                it(@"fails to extract to memory if password is nil", ^{
                    // when
                    NSData* data = [sut extractedData:&error];
                    
                    // then
                    [[data should] beNil];
                });

            });

            context(@"to disk", ^{

                __block NSURL* dirURL = nil;
                __block NSURL* targetURL = nil;
                
                beforeEach(^{
                    dirURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
                    targetURL = [dirURL URLByAppendingPathComponent:sut.name];
                    [[NSFileManager defaultManager] removeItemAtURL:targetURL
                                                              error:NULL];
                });
                
                afterEach(^{
                    [[NSFileManager defaultManager] removeItemAtURL:targetURL
                                                              error:NULL];
                });
                
                it(@"extracts to disk", ^{
                    // when
                    BOOL success = [sut extractToDirectoryAtURL:dirURL
                                                   withPassword:validPassword
                                                          error:&error];
                    
                    // then
                    [[theValue(success) should] beYes];
                    NSData* actualData = [NSData dataWithContentsOfURL:targetURL];
                    [[actualData should] equal:entryData];
                });
                
                it(@"fails to extract to disk if password is invalid", ^{
                    // when
                    BOOL success = [sut extractToDirectoryAtURL:dirURL
                                                   withPassword:invalidPassword
                                                          error:&error];
                    
                    // then
                    [[theValue(success) should] beNo];
                    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:targetURL.path];
                    [[theValue(exists) should] beNo];
                });
                
                it(@"fails to extract to disk if password is nil", ^{
                    // when
                    BOOL success = [sut extractToDirectoryAtURL:dirURL
                                                   withPassword:nil
                                                          error:&error];
                    
                    // then
                    [[theValue(success) should] beNo];
                    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:targetURL.path];
                    [[theValue(exists) should] beNo];
                });

            });

        });

        context(@"extracting directories", ^{
            
            __block NSData* entryData = nil;
            
            beforeEach(^{
                // given
                entryData = [@"stuff\n" dataUsingEncoding:NSUTF8StringEncoding];
                archive = [SVZArchive archiveWithURL:fixtureNamed(@"nested")
                                     createIfMissing:NO
                                               error:&error];
                NSAssert(archive, @"fixture not found");
                
                sut = archive.entries[1];
            });
            
            it(@"extracts to memory as empty data", ^{
                // when
                NSData* data = [sut extractedData:&error];
                
                // then
                [[theValue(data.length) should] beZero];
            });
            
            it(@"extracts to disk as directory", ^{
                // given
                NSURL* dirURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
                NSURL* targetURL = [dirURL URLByAppendingPathComponent:sut.name];
                [[NSFileManager defaultManager] removeItemAtURL:targetURL
                                                          error:NULL];
                
                // when
                BOOL success = [sut extractToDirectoryAtURL:dirURL error:&error];
                
                // then
                [[theValue(success) should] beYes];
                NSNumber* isDir = nil;
                [targetURL getResourceValue:&isDir
                                     forKey:NSURLIsDirectoryKey
                                      error:NULL];
                [[theValue(isDir.boolValue) should] beYes];
                
                [[NSFileManager defaultManager] removeItemAtURL:targetURL
                                                          error:NULL];
            });
            
            it(@"extracts to stream", ^{
                // given
                NSOutputStream* stream = [NSOutputStream outputStreamToMemory];
                
                // when
                BOOL success = [sut extractToStream:stream
                                              error:&error];
                
                // then
                [[theValue(success) should] beYes];
                NSData* actualData = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
                [[theValue(actualData.length) should] beZero];
            });
            
        });
        
    });
    
});

SPEC_END
