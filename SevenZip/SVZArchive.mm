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
#include "CPP/Windows/PropVariantConv.h"
#include "CPP/Windows/TimeUtils.h"
#include "CPP/Common/UTFConvert.h"

#include "SVZArchiveOpenCallback.h"
#include "SVZArchiveUpdateCallback.h"
#include "SVZInFileStream.h"
#include "SVZOutFileStream.h"

#import "SVZArchiveEntry_Private.h"
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
                     createIfMissing:aShouldCreate
                               error:aError];
}

- (SVZ_NULLABLE instancetype)initWithURL:(NSURL*)aURL
                         createIfMissing:(BOOL)aShouldCreate
                                   error:(NSError**)aError {
    NSParameterAssert(aURL);
    NSAssert([aURL isFileURL], @"url must point to a local file");
    
    self = [super init];
    if (self) {
        _url = aURL;
        _fileManager = [NSFileManager defaultManager];
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
        
        item.Attrib = entry.attributes;
        item.Size = entry.uncompressedSize;
        item.Name = ToUString(entry.name);
        item.IsDir = entry.isDirectory;
        
        NWindows::NTime::UnixTimeToFileTime([entry.creationDate timeIntervalSince1970], item.CTime);
        NWindows::NTime::UnixTimeToFileTime([entry.modificationDate timeIntervalSince1970], item.MTime);
        NWindows::NTime::UnixTimeToFileTime([entry.accessDate timeIntervalSince1970], item.ATime);
        
        item.FullPath = us2fs(ToUString(entry.url.path));
        
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

    SVZ::ArchiveUpdateCallback* updateCallbackImpl = new SVZ::ArchiveUpdateCallback();
    CMyComPtr<IArchiveUpdateCallback2> updateCallback(updateCallbackImpl);
    updateCallbackImpl->PasswordIsDefined = false;
    updateCallbackImpl->Init(&archiveItems);
    
    result = outArchive->UpdateItems(outputStream, archiveItems.Size(), updateCallback);
    
    updateCallbackImpl->Finalize();
    
    if (result != S_OK || updateCallbackImpl->FailedFiles.Size() != 0) {
        SetError(aError, kSVZArchiveErrorUpdateFailed, nil);
        return NO;
    }
    
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
    
    if (archive->Open(inputStream, nullptr, openCallback) != S_OK) {
        SetError(aError, kSVZArchiveErrorInvalidArchive, nil);
        return NO;
    }

    self.archive = archive;
    return YES;
}

@end
