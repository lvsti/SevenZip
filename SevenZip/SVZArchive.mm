//
//  SVZArchive.m
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "SVZArchive.h"
#import "SVZArchive_Private.h"

#include "IDecl.h"
#include "SVZArchiveOpenCallback.h"
#include "SVZArchiveUpdateCallback.h"
#include "SVZInFileStream.h"
#include "SVZOutFileStream.h"

#include "CPP/Windows/PropVariantConv.h"
#include "CPP/Windows/TimeUtils.h"
#include "CPP/Common/UTFConvert.h"

#import "SVZArchiveEntry_Private.h"
#import "SVZStoredArchiveEntry.h"

int g_CodePage = -1;

NSString* const kSVZArchiveErrorDomain = @"SVZArchiveErrorDomain";

#define INITGUID
#include "MyGuidDef.h"
DEFINE_GUID(CLSIDFormat7z, 0x23170F69, 0x40C1, 0x278A, 0x10, 0x00, 0x00, 0x01, 0x10, 0x07, 0x00, 0x00);
#undef INITGUID

STDAPI CreateArchiver(const GUID *clsid, const GUID *iid, void **outObject);


static UString ToUString(NSString* str) {
    NSUInteger byteCount = [str lengthOfBytesUsingEncoding:NSUTF32LittleEndianStringEncoding];
    wchar_t* buf = (wchar_t*)malloc(byteCount + sizeof(wchar_t));
    buf[str.length] = 0;
    [str getBytes:buf
        maxLength:byteCount
       usedLength:NULL
         encoding:NSUTF32LittleEndianStringEncoding
          options:0
            range:NSMakeRange(0, str.length)
   remainingRange:NULL];
    UString ustr(buf);
    free(buf);

    return ustr;
}

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

+ (nullable instancetype)archiveWithURL:(NSURL*)aURL
                        createIfMissing:(BOOL)aShouldCreate
                                  error:(NSError**)aError {
    return [[self alloc] initWithURL:aURL
                     createIfMissing:aShouldCreate
                               error:aError];
}

- (nullable instancetype)initWithURL:(NSURL*)aURL
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

- (BOOL)readEntries:(NSError**)aError {
    CMyComPtr<IInArchive> archive;
    HRESULT result = CreateArchiver(&CLSIDFormat7z, &IID_IInArchive, (void **)&archive);
    NSAssert(result == S_OK, @"cannot instantiate archiver");
    self.archive = archive;
    
    SVZ::InFileStream* inputStreamImpl = new SVZ::InFileStream();
    CMyComPtr<IInStream> inputStream(inputStreamImpl);
    
    if (!inputStreamImpl->Open(self.url.path.UTF8String)) {
        SetError(aError, kSVZArchiveErrorOpenFailed, nil);
        return NO;
    }
    
    SVZ::ArchiveOpenCallback* openCallbackImpl = new SVZ::ArchiveOpenCallback();
    CMyComPtr<IArchiveOpenCallback> openCallback(openCallbackImpl);
    openCallbackImpl->PasswordIsDefined = false;
    // openCallbackSpec->PasswordIsDefined = true;
    // openCallbackSpec->Password = L"1";
    
    const UInt64 scanSize = 1 << 23;
    if (self.archive->Open(inputStream, &scanSize, openCallback) != S_OK) {
        SetError(aError, kSVZArchiveErrorInvalidArchive, nil);
        self.archive = nullptr;
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

- (BOOL)updateEntries:(SVZ_GENERIC(NSArray, SVZArchiveEntry*)*)aEntries
                error:(NSError**)aError {
    CObjectVector<SVZ::CDirItem> dirItems;
    
    for (SVZArchiveEntry* entry in aEntries) {
        SVZ::CDirItem di;
        
        di.Attrib = entry.attributes;
        di.Size = entry.uncompressedSize;
        
        NWindows::NTime::UnixTimeToFileTime([entry.creationDate timeIntervalSince1970], di.CTime);
        NWindows::NTime::UnixTimeToFileTime([entry.modificationDate timeIntervalSince1970], di.MTime);
        NWindows::NTime::UnixTimeToFileTime([entry.accessDate timeIntervalSince1970], di.ATime);
        
        di.Name = ToUString(entry.name);
        di.FullPath = us2fs(ToUString(entry.url.path));
        
        dirItems.Add(di);
    }
    
    SVZ::OutFileStream* outFileStreamImpl = new SVZ::OutFileStream();
    CMyComPtr<IOutStream> outFileStream = outFileStreamImpl;
    if (!outFileStreamImpl->Open(self.url.path.UTF8String)) {
        SetError(aError, kSVZArchiveErrorCreateFailed, nil);
        return NO;
    }
    
    CMyComPtr<IOutArchive> outArchive;
    HRESULT result = CreateArchiver(&CLSIDFormat7z, &IID_IOutArchive, (void **)&outArchive);
    NSAssert(result == S_OK, @"cannot instantiate archiver");

    SVZ::ArchiveUpdateCallback* updateCallbackImpl = new SVZ::ArchiveUpdateCallback();
    CMyComPtr<IArchiveUpdateCallback2> updateCallback(updateCallbackImpl);
    updateCallbackImpl->PasswordIsDefined = false;
    updateCallbackImpl->Init(&dirItems);
    
    result = outArchive->UpdateItems(outFileStream, dirItems.Size(), updateCallback);
    
    updateCallbackImpl->Finalize();
    
    if (result != S_OK || updateCallbackImpl->FailedFiles.Size() != 0) {
        SetError(aError, kSVZArchiveErrorUpdateFailed, nil);
        return NO;
    }
    
    return YES;
}

@end
