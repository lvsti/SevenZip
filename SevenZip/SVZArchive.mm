//
//  SVZArchive.m
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "SVZArchive.h"
#import "SVZArchive_Private.h"

#include "CPP/7zip/IDecl.h"
#include "CPP/Windows/PropVariant.h"
#include "CPP/Windows/PropVariantConv.h"
#include "CPP/Windows/TimeUtils.h"
#include "CPP/Common/UTFConvert.h"

#include "SVZArchiveOpenCallback.h"
#include "SVZArchiveUpdateCallback.h"
#include "SVZInFileStream.h"
#include "SVZOutFileStream.h"

#import "SVZArchiveEntry_Private.h"
#import "SVZBridgedInputStream.h"
#import "SVZStoredArchiveEntry.h"
#import "SVZUtils.h"

int g_CodePage = -1;

NSString* const kSVZArchiveErrorDomain = @"SVZArchiveErrorDomain";

#define INITGUID
#include "MyGuidDef.h"
DEFINE_GUID(CLSIDFormat7z, 0x23170F69, 0x40C1, 0x278A, 0x10, 0x00, 0x00, 0x01, 0x10, 0x07, 0x00, 0x00);
#undef INITGUID

STDAPI CreateArchiver(const GUID *clsid, const GUID *iid, void **outObject);


static void SetError(NSError** aError, SVZArchiveError aCode, NSDictionary* userInfo) {
    if (!aError) {
        return;
    }
    
    *aError = [NSError errorWithDomain:kSVZArchiveErrorDomain
                                  code:aCode
                              userInfo:userInfo];
}


@interface SVZArchive ()

@property (nonatomic, strong, readonly) NSFileManager* fileManager;

@end


@implementation SVZArchive

+ (SVZ_NULLABLE instancetype)archiveWithURL:(NSURL*)aURL
                            createIfMissing:(BOOL)aShouldCreate
                                      error:(NSError**)aError {
    return [[self alloc] initWithURL:aURL
                            password:nil
                     createIfMissing:aShouldCreate
                               error:aError];
}

+ (SVZ_NULLABLE instancetype)archiveWithURL:(NSURL*)aURL
                                   password:(NSString*)aPassword
                            createIfMissing:(BOOL)aShouldCreate
                                      error:(NSError**)aError {
    return [[self alloc] initWithURL:aURL
                            password:aPassword
                     createIfMissing:aShouldCreate
                               error:aError];
}

- (SVZ_NULLABLE instancetype)initWithURL:(NSURL*)aURL
                                password:(NSString*)aPassword
                         createIfMissing:(BOOL)aShouldCreate
                                   error:(NSError**)aError {
    NSParameterAssert(aURL);
    NSAssert([aURL isFileURL], @"url must point to a local file");
    
    self = [super init];
    if (self) {
        _url = aURL;
        _fileManager = [[self class] fileManager];
        _password = [aPassword copy];
        _entries = @[];
        
        BOOL isDir = NO;
        if ([self.fileManager fileExistsAtPath:aURL.path isDirectory:&isDir]) {
            // opening existing archive
            if (isDir) {
                SetError(aError, kSVZArchiveErrorInvalidArchive, nil);
                self = nil;
            }
            else if (![self readEntries:aError]) {
                self = nil;
            }
        } else {
            // archive doesn't exist yet
            if (!aShouldCreate) {
                // and this is an error
                SetError(aError, kSVZArchiveErrorFileNotFound, nil);
                self = nil;
            }
        }
    }
    return self;
}

- (void)dealloc {
    _archive = nullptr;
}

- (BOOL)updateEntries:(SVZ_GENERIC(NSArray, SVZArchiveEntry*)*)aEntries
                error:(NSError**)aError {
    CObjectVector<SVZ::ArchiveItem> archiveItems;
    SVZ_GENERIC(NSMutableArray, SVZStoredArchiveEntry*)* storedEntries = [NSMutableArray arrayWithCapacity:aEntries.count];
    
    int index = 0;
    for (SVZArchiveEntry* entry in aEntries) {
        SVZ::ArchiveItem item;

        if ([entry isKindOfClass:[SVZStoredArchiveEntry class]]) {
            SVZStoredArchiveEntry* storedEntry = (SVZStoredArchiveEntry*)entry;
            SVZArchive* hostArchive = storedEntry.archive;
            
            if (!hostArchive || hostArchive.archive != self.archive) {
                // foreign entries are not supported
                SetError(aError, kSVZArchiveErrorForeignEntry, @{@"entry": entry});
                return NO;
            }
            
            item.CurrentIndex = (Int32)storedEntry.index;
            [storedEntries addObject:storedEntry];
        } else {
            item.CurrentIndex = SVZ::ArchiveItem::kNewItemIndex;
        }
        
        item.ID = index++;
        item.Attrib = entry.attributes;
        item.Size = entry.uncompressedSize;
        item.Name = ToUString(entry.name);
        item.IsDir = entry.isDirectory;
        
        NWindows::NTime::UnixTimeToFileTime([entry.creationDate timeIntervalSince1970], item.CTime);
        NWindows::NTime::UnixTimeToFileTime([entry.modificationDate timeIntervalSince1970], item.MTime);
        NWindows::NTime::UnixTimeToFileTime([entry.accessDate timeIntervalSince1970], item.ATime);
        
        archiveItems.Add(item);
    }
    
    SVZ::OutFileStream* outFileStreamImpl = new SVZ::OutFileStream();
    CMyComPtr<IOutStream> outputStream = outFileStreamImpl;
    if (!outFileStreamImpl->Open(self.url.path.UTF8String)) {
        SetError(aError, kSVZArchiveErrorFileOpenFailed, nil);
        return NO;
    }
    
    CMyComPtr<IOutArchive> outArchive;
    HRESULT result;
    
    if (storedEntries.count > 0) {
        result = self.archive->QueryInterface(IID_IOutArchive, (void**)&outArchive);
        NSAssert(result == S_OK, @"archiver object does not support updates");
    }
    
    if (!outArchive) {
        result = CreateArchiver(&CLSIDFormat7z, &IID_IOutArchive, (void**)&outArchive);
        NSAssert(result == S_OK, @"cannot instantiate archiver");
    }

    if (self.usesHeaderEncryption) {
        CMyComPtr<ISetProperties> setProperties;
        result = outArchive->QueryInterface(IID_ISetProperties, (void**)&setProperties);
        NSAssert(result == S_OK, @"archiver object does not support setting properties");
        
        const wchar_t* names[] = { L"he" };
        const unsigned kNumProps = ARRAY_SIZE(names);
        NWindows::NCOM::CPropVariant values[kNumProps] = { L"on" };
        
        setProperties->SetProperties(names, values, kNumProps);
    }
    
    SVZ::ArchiveUpdateCallback* updateCallbackImpl = new SVZ::ArchiveUpdateCallback();
    CMyComPtr<IArchiveUpdateCallback2> updateCallback(updateCallbackImpl);
    if (self.password) {
        updateCallbackImpl->PasswordIsDefined = true;
        updateCallbackImpl->Password = ToUString(self.password);
    }
    
    updateCallbackImpl->Init(&archiveItems, [&] (Int32 itemID) -> CMyComPtr<ISequentialInStream> {
        @autoreleasepool {
            SVZArchiveEntry* entry = aEntries[itemID];
            CMyComPtr<ISequentialInStream> inStream = new SVZ::BridgedInputStream(entry.dataStream);
            return inStream;
        }
    });
    
    result = outArchive->UpdateItems(outputStream, archiveItems.Size(), updateCallback);
    
    updateCallbackImpl->Finalize();
    
    if (result != S_OK || updateCallbackImpl->FailedFiles.Size() != 0) {
        SetError(aError, kSVZArchiveErrorUpdateFailed, nil);
        return NO;
    }

    // explicit close is required to flush the stream to disk before reading it back
    outFileStreamImpl->Close();
    
    [storedEntries makeObjectsPerformSelector:@selector(invalidate)];
    
    return [self readEntries:aError];
}

#pragma mark - private methods:

- (BOOL)readEntries:(NSError**)aError {
    if (![self openArchive:aError]) {
        return NO;
    }
    
    UInt32 numItems = 0;
    self.archive->GetNumberOfItems(&numItems);
    SVZ_GENERIC(NSMutableArray, SVZArchiveEntry*)* storedEntries = [NSMutableArray arrayWithCapacity:numItems];
    
    for (UInt32 i = 0; i < numItems; i++) {
        SVZStoredArchiveEntry* entry = [[SVZStoredArchiveEntry alloc] initWithIndex:i inArchive:self];
        [storedEntries addObject:entry];
    }
    
    _entries = [storedEntries copy];
    
    return YES;
}

- (BOOL)openArchive:(NSError**)aError {
    CMyComPtr<IInArchive> archive;
    HRESULT result = CreateArchiver(&CLSIDFormat7z, &IID_IInArchive, (void **)&archive);
    NSAssert(result == S_OK, @"cannot instantiate archiver");
    
    SVZ::InFileStream* inFileStreamImpl = new SVZ::InFileStream();
    CMyComPtr<IInStream> inputStream(inFileStreamImpl);
    
    if (!inFileStreamImpl->Open(self.url.path.UTF8String)) {
        SetError(aError, kSVZArchiveErrorFileOpenFailed, nil);
        return NO;
    }
    
    SVZ::ArchiveOpenCallback* openCallbackImpl = new SVZ::ArchiveOpenCallback();
    CMyComPtr<IArchiveOpenCallback> openCallback(openCallbackImpl);
    if (self.password) {
        openCallbackImpl->passwordIsDefined = true;
        openCallbackImpl->password = ToUString(self.password);
    }
    
    if (archive->Open(inputStream, nullptr, openCallback) != S_OK) {
        SetError(aError, kSVZArchiveErrorInvalidArchive, nil);
        return NO;
    }

    _usesHeaderEncryption = openCallbackImpl->didAskForPassword;
    
    self.archive = archive;
    return YES;
}

#pragma mark - UT helpers:

+ (NSFileManager*)fileManager {
    return [NSFileManager defaultManager];
}

@end
