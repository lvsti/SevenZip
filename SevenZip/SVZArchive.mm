//
//  SVZArchive.m
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "SVZArchive.h"

#include "IDecl.h"
#include "SVZArchiveOpenCallback.h"
#include "SVZArchiveUpdateCallback.h"
#include "SVZInFileStream.h"
#include "SVZOutFileStream.h"

#include "CPP/Windows/PropVariant.h"
#include "CPP/Windows/PropVariantConv.h"
#include "CPP/Common/UTFConvert.h"

#import "SVZArchiveEntry_Private.h"

int g_CodePage = -1;

NSString* const kSVZArchiveErrorDomain = @"SVZArchiveErrorDomain";

#define INITGUID
#include "MyGuidDef.h"
DEFINE_GUID(CLSIDFormat7z, 0x23170F69, 0x40C1, 0x278A, 0x10, 0x00, 0x00, 0x01, 0x10, 0x07, 0x00, 0x00);
#undef INITGUID

STDAPI CreateArchiver(const GUID *clsid, const GUID *iid, void **outObject);

static void UnixTimeToFileTime(time_t t, FILETIME* pft) {
    LONGLONG ll = t * 10000000LL + 116444736000000000LL;
    pft->dwLowDateTime = (DWORD)ll;
    pft->dwHighDateTime = ll >> 32;
}

static time_t FileTimeToUnixTime(const FILETIME* pft) {
    LONGLONG ll = (((time_t)pft->dwHighDateTime) << 32) | pft->dwLowDateTime;
    ll -= 116444736000000000LL;
    ll /= 10000000LL;
    return (time_t)ll;
}


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

static NSString* FromUString(const UString& ustr) {
    NSData* ustrBuf = [NSData dataWithBytesNoCopy:(void*)ustr.Ptr()
                                           length:ustr.Len()*sizeof(wchar_t)
                                     freeWhenDone:NO];
    return [[NSString alloc] initWithData:ustrBuf encoding:NSUTF32LittleEndianStringEncoding];
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

@property (nonatomic, copy, readwrite) NSArray* entries;

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

- (BOOL)readEntries:(NSError**)aError {
    CMyComPtr<IInArchive> archive;
    HRESULT result = CreateArchiver(&CLSIDFormat7z, &IID_IInArchive, (void **)&archive);
    NSAssert(result == S_OK, @"cannot instantiate archiver");
    
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
    if (archive->Open(inputStream, &scanSize, openCallback) != S_OK) {
        SetError(aError, kSVZArchiveErrorInvalidArchive, nil);
        return NO;
    }
    
    UInt32 numItems = 0;
    archive->GetNumberOfItems(&numItems);
    NSMutableArray* storedEntries = [NSMutableArray arrayWithCapacity:numItems];
    NWindows::NCOM::CPropVariant prop;
        
    for (UInt32 i = 0; i < numItems; i++) {
        SVZArchiveEntry* entry = [SVZArchiveEntry new];

        archive->GetProperty(i, kpidPath, &prop);
        entry.name = FromUString(UString(prop.bstrVal));
        
        archive->GetProperty(i, kpidAttrib, &prop);
        entry.attributes = prop.ulVal;
        
        archive->GetProperty(i, kpidCTime, &prop);
        entry.creationDate = [NSDate dateWithTimeIntervalSince1970:FileTimeToUnixTime(&prop.filetime)];

        archive->GetProperty(i, kpidMTime, &prop);
        entry.modificationDate = [NSDate dateWithTimeIntervalSince1970:FileTimeToUnixTime(&prop.filetime)];
        
        archive->GetProperty(i, kpidATime, &prop);
        entry.accessDate = [NSDate dateWithTimeIntervalSince1970:FileTimeToUnixTime(&prop.filetime)];
        
        archive->GetProperty(i, kpidIsDir, &prop);
        BOOL isDir = prop.boolVal;
        
        if (!isDir) {
            archive->GetProperty(i, kpidSize, &prop);
            entry.uncompressedSize = prop.uhVal.QuadPart;
            
            archive->GetProperty(i, kpidPackSize, &prop);
            entry.compressedSize = prop.uhVal.QuadPart;
        }
        
        [storedEntries addObject:entry];
    }
    
    self.entries = storedEntries;
    
    return YES;
}

- (BOOL)updateEntries:(NSArray<SVZArchiveEntry*>*)aEntries
                error:(NSError**)aError {
    CObjectVector<SVZ::CDirItem> dirItems;
    
    for (SVZArchiveEntry* entry in aEntries) {
        SVZ::CDirItem di;
        
        di.Attrib = entry.attributes;
        di.Size = entry.uncompressedSize;
        
        UnixTimeToFileTime([entry.creationDate timeIntervalSince1970], &di.CTime);
        UnixTimeToFileTime([entry.modificationDate timeIntervalSince1970], &di.MTime);
        UnixTimeToFileTime([entry.accessDate timeIntervalSince1970], &di.ATime);
        
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
