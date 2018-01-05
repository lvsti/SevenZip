//
//  UT_SVZArchive.m
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 12. 03..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <SevenZip/SevenZip.h>

@interface SVZArchive (UT)
+ (NSFileManager*)fileManager;
@end


SPEC_BEGIN(ArchiveSpec)

describe(@"Archive", ^{
    
    __block SVZArchive* sut = nil;
    __block NSError* error = nil;
    __block NSFileManager* fileManagerMock = nil;
    __block NSURL* dummyURL = [NSURL fileURLWithPath:@"/foo/bar.7z"];
    
    NSURL* (^fixtureNamed)(NSString*) = ^NSURL*(NSString* name) {
        return [[NSBundle bundleForClass:self] URLForResource:name withExtension:@"7z"];
    };
    
    beforeEach(^{
        error = nil;
        
        fileManagerMock = [NSFileManager mock];
        [fileManagerMock stub:@selector(fileExistsAtPath:isDirectory:) andReturn:theValue(YES)];

        [SVZArchive stub:@selector(fileManager) andReturn:fileManagerMock];
    });
    
    afterEach(^{
        sut = nil;
    });
    
    context(@"opening", ^{
        
        context(@"existing URL", ^{
            
            context(@"success", ^{
                
                it(@"returns a new instance", ^{
                    // when
                    sut = [SVZArchive archiveWithURL:fixtureNamed(@"basic")
                                     createIfMissing:NO
                                               error:&error];
                    
                    // then
                    [[sut should] beNonNil];
                });
                
                it(@"populates the `entries` array with the archive contents", ^{
                    // when
                    sut = [SVZArchive archiveWithURL:fixtureNamed(@"basic")
                                     createIfMissing:NO
                                               error:&error];
                    
                    // then
                    [[sut.entries should] haveCountOf:1];
                });
                
                it(@"doesn't care about password protection if header encryption is off", ^{
                    // when
                    sut = [SVZArchive archiveWithURL:fixtureNamed(@"protected")
                                     createIfMissing:NO
                                               error:&error];
                    
                    // then
                    [[sut should] beNonNil];
                });
                
                it(@"opens the archive with header encryption with the correct password", ^{
                    // when
                    sut = [SVZArchive archiveWithURL:fixtureNamed(@"protected_header")
                                            password:@"secret"
                                               error:&error];
                    
                    // then
                    [[sut should] beNonNil];
                });
                
            });
            
            context(@"failure", ^{

                it(@"fails if the URL points to a directory", ^{
                    // given
                    [fileManagerMock stub:@selector(fileExistsAtPath:isDirectory:) withBlock:^id(NSArray *params) {
                        NSValue* ptrValue = params[1];
                        BOOL* isDir = [ptrValue pointerValue];
                        *isDir = YES;
                        return theValue(YES);
                    }];
                    
                    // when
                    sut = [SVZArchive archiveWithURL:dummyURL
                                     createIfMissing:NO
                                               error:&error];
                    
                    // then
                    [[sut should] beNil];
                });

                it(@"fails if the file cannot be opened", ^{
                    // when
                    sut = [SVZArchive archiveWithURL:dummyURL
                                     createIfMissing:NO
                                               error:&error];
                    
                    // then
                    [[sut should] beNil];
                });
                
                it(@"fails if the archive has encrypted headers and no password is provided", ^{
                    // when
                    sut = [SVZArchive archiveWithURL:fixtureNamed(@"protected_header")
                                            password:nil
                                               error:&error];
                    
                    // then
                    [[sut should] beNil];
                });

                it(@"fails if the archive has encrypted headers and a wrong password is provided", ^{
                    // when
                    sut = [SVZArchive archiveWithURL:fixtureNamed(@"protected_header")
                                            password:@"wrong_password"
                                               error:&error];
                    
                    // then
                    [[sut should] beNil];
                });

            });
            
        });
        
        context(@"nonexistent URL", ^{
            
            beforeEach(^{
                [fileManagerMock stub:@selector(fileExistsAtPath:isDirectory:)
                            andReturn:theValue(NO)];
            });

            it(@"returns a new instance if the shouldCreate flag is set", ^{
                // when
                sut = [SVZArchive archiveWithURL:dummyURL
                                 createIfMissing:YES
                                           error:&error];
                
                // then
                [[sut should] beNonNil];
            });
            
            it(@"sets the `url` property to the argument", ^{
                // when
                sut = [SVZArchive archiveWithURL:dummyURL
                                 createIfMissing:YES
                                           error:&error];
                
                // then
                [[sut.url should] equal:dummyURL];
            });

            it(@"returns with error if the shouldCreate flag is not set", ^{
                // when
                sut = [SVZArchive archiveWithURL:dummyURL
                                 createIfMissing:NO
                                           error:&error];
                
                // then
                [[sut should] beNil];
                [[error should] beNonNil];
            });
            
        });
        
    });
    
    context(@"update", ^{

        __block NSURL* targetURL = nil;
        
        beforeEach(^{
            NSString* random = [NSUUID UUID].UUIDString;
            NSString* targetPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:random]
                                    stringByAppendingPathExtension:@"7z"];
            targetURL = [NSURL fileURLWithPath:targetPath];
        });
        
        afterEach(^{
            [[NSFileManager defaultManager] removeItemAtURL:targetURL
                                                      error:NULL];
        });
        
        void (^prepareReadWriteFixtureNamed)(NSString*) = ^(NSString* name) {
            BOOL success = [[NSFileManager defaultManager] copyItemAtURL:fixtureNamed(name)
                                                                   toURL:targetURL
                                                                   error:NULL];
            NSAssert(success, @"failed to prepare fixture");
        };
        
        context(@"success", ^{

            beforeEach(^{
                [fileManagerMock stub:@selector(fileExistsAtPath:isDirectory:) andReturn:theValue(YES)];
            });
            
            it(@"commits changes to disk", ^{
                // given
                prepareReadWriteFixtureNamed(@"basic");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                id oldGen = nil;
                [targetURL getResourceValue:&oldGen
                                     forKey:NSURLGenerationIdentifierKey
                                      error:NULL];

                // when
                BOOL result = [sut updateEntries:sut.entries error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                id newGen = nil;
                NSURL* clonedURL = [NSURL fileURLWithPath:targetURL.path];
                [clonedURL getResourceValue:&newGen
                                     forKey:NSURLGenerationIdentifierKey
                                      error:NULL];
                [[newGen shouldNot] equal:oldGen];
            });
            
            it(@"can remove an entry", ^{
                // given
                prepareReadWriteFixtureNamed(@"basic");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");

                // when
                BOOL result = [sut updateEntries:@[] error:&error];

                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:0];
            });
            
            it(@"can add a directory entry", ^{
                // given
                prepareReadWriteFixtureNamed(@"empty");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");

                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithDirectoryName:@"stuff"];
                
                // when
                BOOL result = [sut updateEntries:@[newEntry] error:&error];

                // then
                [[theValue(result) should] beYes];

                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:1];
                [[[probe.entries.firstObject name] should] equal:newEntry.name];
                [[theValue([probe.entries.firstObject isDirectory]) should] beYes];
            });

            it(@"can add a file entry", ^{
                // given
                prepareReadWriteFixtureNamed(@"empty");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");

                NSData* entryData = [@"stuff" dataUsingEncoding:NSUTF8StringEncoding];
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithFileName:@"stuff.txt"
                                                                          streamBlock:SVZStreamBlockCreateWithData(entryData)];
                
                // when
                BOOL result = [sut updateEntries:@[newEntry] error:&error];

                // then
                [[theValue(result) should] beYes];

                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:1];
                [[[probe.entries.firstObject name] should] equal:newEntry.name];
                [[theValue([probe.entries.firstObject isDirectory]) should] beNo];
                [[theValue([probe.entries.firstObject uncompressedSize]) should] equal:theValue(entryData.length)];
            });

            it(@"can replace an entry", ^{
                // given
                prepareReadWriteFixtureNamed(@"basic");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithDirectoryName:@"stuff"];

                // when
                BOOL result = [sut updateEntries:@[newEntry] error:&error];
                
                // then
                [[theValue(result) should] beYes];

                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:1];
                [[[probe.entries.firstObject name] should] equal:newEntry.name];
            });
            
            it(@"keeps unaltered entries", ^{
                // given
                prepareReadWriteFixtureNamed(@"basic");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                NSAssert(sut.entries.count == 1, @"preconditions fail");
                
                SVZArchiveEntry* oldEntry = sut.entries.firstObject;
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithDirectoryName:@"stuff"];
                NSArray* newEntries = [sut.entries arrayByAddingObject:newEntry];
                
                // when
                BOOL result = [sut updateEntries:newEntries error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:2];
                
                NSInteger newIdx = [probe.entries indexOfObjectPassingTest:^BOOL(SVZArchiveEntry* obj, NSUInteger idx, BOOL* stop) {
                    return [obj.name isEqualToString:newEntry.name];
                }];
                [[theValue(newIdx) shouldNot] equal:theValue(NSNotFound)];
                
                NSInteger oldIdx = [probe.entries indexOfObjectPassingTest:^BOOL(SVZArchiveEntry* obj, NSUInteger idx, BOOL* stop) {
                    return [obj.name isEqualToString:oldEntry.name];
                }];
                [[theValue(oldIdx) shouldNot] equal:theValue(NSNotFound)];
            });
            
            it(@"removes header encryption", ^{
                // given
                prepareReadWriteFixtureNamed(@"protected_header");
                sut = [SVZArchive archiveWithURL:targetURL
                                        password:@"secret"
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                NSAssert(sut.entries.count == 1, @"preconditions fail");
                
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithDirectoryName:@"stuff"];
                NSArray* newEntries = [sut.entries arrayByAddingObject:newEntry];
                
                // when
                BOOL result = [sut updateEntries:newEntries error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:2];
            });
            
        });
        
        context(@"failure", ^{
            
            it(@"fails if a foreign entry is detected", ^{
                // given
                SVZArchive* otherArchive = [SVZArchive archiveWithURL:fixtureNamed(@"basic")
                                                      createIfMissing:NO
                                                                error:NULL];
                NSAssert(otherArchive, @"fixture not found");
                
                prepareReadWriteFixtureNamed(@"nested");
                sut = [SVZArchive archiveWithURL:fixtureNamed(@"nested")
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"invalid fixture");
                
                NSMutableArray* entries = [sut.entries mutableCopy];
                [entries addObject:otherArchive.entries.firstObject];

                // when
                BOOL result = [sut updateEntries:entries error:&error];
                
                // then
                [[theValue(result) should] beNo];
            });
            
            it(@"fails if the archive file cannot be opened", ^{
                // given
                sut = [SVZArchive archiveWithURL:dummyURL
                                 createIfMissing:YES
                                           error:&error];
                
                // when
                BOOL result = [sut updateEntries:@[] error:&error];
                
                // then
                [[theValue(result) should] beNo];
            });
            
            it(@"fails if any entry fails to be committed", ^{
                // given
                prepareReadWriteFixtureNamed(@"empty");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                
                NSInputStream* failingStream = [NSInputStream mock];
                [failingStream stub:@selector(open)];
                [failingStream stub:@selector(close)];
                [failingStream stub:@selector(read:maxLength:) andReturn:theValue(-1)];
                
                NSInputStream* (^failingBlock)(uint64_t*, NSError**) = ^NSInputStream*(uint64_t* aSize, NSError** aError) {
                    *aSize = 10;
                    return failingStream;
                };
                
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithFileName:@"stuff.txt"
                                                                          streamBlock:failingBlock];
                
                // when
                BOOL result = [sut updateEntries:@[newEntry] error:&error];
                
                // then
                [[theValue(result) should] beNo];
            });
            
        });
        
        context(@"with password", ^{
            
            it(@"encrypts new entries with the provided password", ^{
                // given
                prepareReadWriteFixtureNamed(@"basic");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                NSAssert(sut.entries.count == 1, @"preconditions fail");
                
                NSData* entryData = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithFileName:@"bar.txt"
                                                                          streamBlock:SVZStreamBlockCreateWithData(entryData)];
                
                // when
                BOOL result = [sut updateEntries:[sut.entries arrayByAddingObject:newEntry]
                                    withPassword:@"secret"
                                headerEncryption:NO
                                compressionLevel:kSVZCompressionLevelNormal
                                           error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:2];
                newEntry = [probe.entries.firstObject.name isEqualToString:@"bar.txt"] ?
                    probe.entries.firstObject : probe.entries.lastObject;
                
                NSData* newEntryData = [newEntry extractedData:NULL];
                [[newEntryData should] beNil];
                
                newEntryData = [newEntry extractedDataWithPassword:@"secret"
                                                             error:NULL];
                [[newEntryData should] equal:entryData];
            });

            it(@"does not reencrypt existing entries with the provided password", ^{
                // given
                prepareReadWriteFixtureNamed(@"basic");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                NSAssert(sut.entries.count == 1, @"preconditions fail");
                
                NSData* entryData = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithFileName:@"bar.txt"
                                                                          streamBlock:SVZStreamBlockCreateWithData(entryData)];
                
                // when
                BOOL result = [sut updateEntries:[sut.entries arrayByAddingObject:newEntry]
                                    withPassword:@"secret"
                                headerEncryption:NO
                                compressionLevel:kSVZCompressionLevelNormal
                                           error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:2];
                SVZArchiveEntry* oldEntry = [probe.entries.firstObject.name isEqualToString:@"bar.txt"] ?
                    probe.entries.lastObject : probe.entries.firstObject;
                
                NSData* oldEntryData = [oldEntry extractedData:NULL];
                [[oldEntryData should] beNonNil];
            });

            it(@"applies header encryption when the flag is set", ^{
                // given
                prepareReadWriteFixtureNamed(@"basic");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                NSAssert(sut.entries.count == 1, @"preconditions fail");
                
                NSData* entryData = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithFileName:@"bar.txt"
                                                                          streamBlock:SVZStreamBlockCreateWithData(entryData)];
                
                // when
                BOOL result = [sut updateEntries:[sut.entries arrayByAddingObject:newEntry]
                                    withPassword:@"secret"
                                headerEncryption:YES
                                compressionLevel:kSVZCompressionLevelNormal
                                           error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNil];

                probe = [SVZArchive archiveWithURL:targetURL
                                          password:@"secret"
                                             error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:2];
            });
            
            it(@"removes header encryption when the flag is not set", ^{
                // given
                prepareReadWriteFixtureNamed(@"protected_header");
                sut = [SVZArchive archiveWithURL:targetURL
                                        password:@"secret"
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                NSAssert(sut.entries.count == 1, @"preconditions fail");
                
                NSData* entryData = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithFileName:@"bar.txt"
                                                                          streamBlock:SVZStreamBlockCreateWithData(entryData)];
                
                // when
                BOOL result = [sut updateEntries:[sut.entries arrayByAddingObject:newEntry]
                                    withPassword:@"secret"
                                headerEncryption:NO
                                compressionLevel:kSVZCompressionLevelNormal
                                           error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:2];
            });
            
        });

        context(@"with nil password", ^{
            
            it(@"doesn't apply encryption to new entries", ^{
                // given
                prepareReadWriteFixtureNamed(@"basic");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                NSAssert(sut.entries.count == 1, @"preconditions fail");
                
                NSData* entryData = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithFileName:@"bar.txt"
                                                                          streamBlock:SVZStreamBlockCreateWithData(entryData)];
                
                // when
                BOOL result = [sut updateEntries:[sut.entries arrayByAddingObject:newEntry]
                                    withPassword:nil
                                headerEncryption:NO
                                compressionLevel:kSVZCompressionLevelNormal
                                           error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:2];
                newEntry = [probe.entries.firstObject.name isEqualToString:@"bar.txt"] ?
                    probe.entries.firstObject : probe.entries.lastObject;
                
                NSData* newEntryData = [newEntry extractedData:NULL];
                [[newEntryData should] equal:entryData];
            });
            
            it(@"does not remove encryption from existing entries", ^{
                // given
                prepareReadWriteFixtureNamed(@"protected");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                NSAssert(sut.entries.count == 1, @"preconditions fail");
                
                NSData* entryData = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithFileName:@"bar.txt"
                                                                          streamBlock:SVZStreamBlockCreateWithData(entryData)];
                
                // when
                BOOL result = [sut updateEntries:[sut.entries arrayByAddingObject:newEntry]
                                    withPassword:nil
                                headerEncryption:NO
                                compressionLevel:kSVZCompressionLevelNormal
                                           error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:2];
                SVZArchiveEntry* oldEntry = [probe.entries.firstObject.name isEqualToString:@"bar.txt"] ?
                    probe.entries.lastObject : probe.entries.firstObject;
                
                NSData* oldEntryData = [oldEntry extractedData:NULL];
                [[oldEntryData should] beNil];
            });
            
            it(@"removes header encryption (if present) regardless of the flag", ^{
                // given
                prepareReadWriteFixtureNamed(@"protected_header");
                sut = [SVZArchive archiveWithURL:targetURL
                                        password:@"secret"
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                NSAssert(sut.entries.count == 1, @"preconditions fail");
                
                NSData* entryData = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithFileName:@"bar.txt"
                                                                          streamBlock:SVZStreamBlockCreateWithData(entryData)];
                
                // when
                BOOL result = [sut updateEntries:[sut.entries arrayByAddingObject:newEntry]
                                    withPassword:nil
                                headerEncryption:YES
                                compressionLevel:kSVZCompressionLevelNormal
                                           error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:2];
            });
            
            it(@"doesn't add header encryption (if not present) regardless of the flag", ^{
                // given
                prepareReadWriteFixtureNamed(@"basic");
                sut = [SVZArchive archiveWithURL:targetURL
                                 createIfMissing:NO
                                           error:NULL];
                NSAssert(sut, @"cannot initialize archive");
                NSAssert(sut.entries.count == 1, @"preconditions fail");
                
                NSData* entryData = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
                SVZArchiveEntry* newEntry = [SVZArchiveEntry archiveEntryWithFileName:@"bar.txt"
                                                                          streamBlock:SVZStreamBlockCreateWithData(entryData)];
                
                // when
                BOOL result = [sut updateEntries:[sut.entries arrayByAddingObject:newEntry]
                                    withPassword:nil
                                headerEncryption:YES
                                compressionLevel:kSVZCompressionLevelNormal
                                           error:&error];
                
                // then
                [[theValue(result) should] beYes];
                
                SVZArchive* probe = [SVZArchive archiveWithURL:targetURL
                                               createIfMissing:NO
                                                         error:NULL];
                [[probe should] beNonNil];
                [[probe.entries should] haveCountOf:2];
            });
            
        });

    });
    
    context(@"codec support", ^{
        
        NSString* fixturesDir = [[NSBundle bundleForClass:self].resourcePath
                                 stringByAppendingPathComponent:@"codec_fixtures"];
        NSArray* fixtures = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fixturesDir error:NULL];
        
        for (NSString* fixtureName in fixtures) {
            it([NSString stringWithFormat:@"supports %@", fixtureName], ^{
                // given
                NSURL* fixtureURL = [NSURL fileURLWithPath:[fixturesDir stringByAppendingPathComponent:fixtureName]];
                NSError* error = nil;
                
                // when
                sut = [SVZArchive archiveWithURL:fixtureURL
                                 createIfMissing:NO
                                           error:&error];
                NSData* data = [sut.entries.firstObject extractedData:&error];
                NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                // then
                [[sut should] beNonNil];
                [[data should] beNonNil];
                [[str should] equal:@"Eureka!"];
            });
        }
        
    });
    
});

SPEC_END

