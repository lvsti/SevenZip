//
//  SVZArchive.m
//  ObjC7z
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

#import "SVZArchiveEntry.h"

int g_CodePage = -1;


#define INITGUID
#include "MyGuidDef.h"
DEFINE_GUID(CLSIDFormat7z, 0x23170F69, 0x40C1, 0x278A, 0x10, 0x00, 0x00, 0x01, 0x10, 0x07, 0x00, 0x00);
#undef INITGUID

STDAPI CreateArchiver(const GUID *clsid, const GUID *iid, void **outObject);

void UnixTimeToFileTime(time_t t, FILETIME* pft)
{
    LONGLONG ll = t * 10000000LL + 116444736000000000LL;
    pft->dwLowDateTime = (DWORD)ll;
    pft->dwHighDateTime = ll >> 32;
}

@interface SVZArchive ()
@property (nonatomic, strong, readonly) NSFileManager* fileManager;
@end


@implementation SVZArchive

+ (nullable instancetype)archiveWithURL:(NSURL*)url
                                  error:(NSError**)error {
    return [[self alloc] initWithURL:url error:error];
}

- (nullable instancetype)initWithURL:(NSURL*)url error:(NSError**)error {
    self = [super init];
    if (self) {
        _url = url;
        _fileManager = [NSFileManager defaultManager];
        
        [self readEntries:error];
    }
    return self;
}

- (BOOL)readEntries:(NSError**)aError {
    SVZ::ArchiveOpenCallback openCallback;
 
    CMyComPtr<IInArchive> archive;
    if (CreateArchiver(&CLSIDFormat7z, &IID_IInArchive, (void **)&archive) != S_OK) {
        return NO;
    }
    
    SVZ::InFileStream* inputStreamImpl = new SVZ::InFileStream();
    CMyComPtr<IInStream> inputStream = inputStreamImpl;
    
    if (!inputStreamImpl->Open(self.url.path.UTF8String)) {
        NSLog(@"cannot open archive at %@", self.url);
        return NO;
    }
    
    {
        SVZ::ArchiveOpenCallback* openCallbackImpl = new SVZ::ArchiveOpenCallback();
        CMyComPtr<IArchiveOpenCallback> openCallback(openCallbackImpl);
        openCallbackImpl->PasswordIsDefined = false;
        // openCallbackSpec->PasswordIsDefined = true;
        // openCallbackSpec->Password = L"1";
        
        const UInt64 scanSize = 1 << 23;
        if (archive->Open(inputStream, &scanSize, openCallback) != S_OK) {
            NSLog(@"file is not a valid archive: %@", self.url);
            return NO;
        }
    }
    
    UInt32 numItems = 0;
    archive->GetNumberOfItems(&numItems);
    for (UInt32 i = 0; i < numItems; i++) {
        {
            // Get uncompressed size of file
            NWindows::NCOM::CPropVariant prop;
            archive->GetProperty(i, kpidSize, &prop);
//            char s[32];
//            ConvertPropVariantToShortString(prop, s);
//            PrintString(s);
//            PrintString("  ");
        }
        {
            // Get name of file
            NWindows::NCOM::CPropVariant prop;
            archive->GetProperty(i, kpidPath, &prop);
            if (prop.vt == VT_BSTR) {
//                PrintString(prop.bstrVal);
            } else if (prop.vt != VT_EMPTY) {
//                PrintString("ERROR!");
            }
        }
    }
    
    return YES;
}

- (BOOL)addFileAtURL:(NSURL*)url {
    SVZArchiveEntry* entry = [SVZArchiveEntry new];
    entry.name = url.lastPathComponent;
    return [self updateEntries:@[entry]
                         error:NULL];
}

- (BOOL)updateEntries:(NSArray<SVZArchiveEntry*>*)entries
                error:(NSError**)error {
    CObjectVector<SVZ::CDirItem> dirItems;
    
    for (SVZArchiveEntry* entry in entries) {
        SVZ::CDirItem di;
        
        NSDictionary* attributes = [self.fileManager attributesOfItemAtPath:entry.name error:error];
        if (!attributes) {
            return NO;
        }
        
        di.Attrib = 0;
        di.Size = [attributes[NSFileSize] unsignedLongLongValue];
        
        UnixTimeToFileTime([attributes[NSFileCreationDate] timeIntervalSince1970], &di.CTime);
        UnixTimeToFileTime([attributes[NSFileModificationDate] timeIntervalSince1970], &di.MTime);
        UnixTimeToFileTime([attributes[NSFileModificationDate] timeIntervalSince1970], &di.ATime);
        
        NSUInteger byteCount = [entry.name lengthOfBytesUsingEncoding:NSUTF32LittleEndianStringEncoding];
        wchar_t* buf = (wchar_t*)malloc(byteCount + sizeof(wchar_t));
        buf[entry.name.length] = 0;
        [entry.name getBytes:buf
                   maxLength:byteCount
                  usedLength:NULL
                    encoding:NSUTF32LittleEndianStringEncoding
                     options:0
                       range:NSMakeRange(0, entry.name.length)
              remainingRange:NULL];
//        [entry.name getCharacters:buf range:NSMakeRange(0, entry.name.length)];
        di.Name = UString((const wchar_t*)buf);
        free(buf);
        
        di.FullPath = us2fs(di.Name);
//        ConvertUTF8ToUnicode(entry.name.UTF8String, di.FullPath);
        
        dirItems.Add(di);
    }
    
    SVZ::OutFileStream* outFileStreamImpl = new SVZ::OutFileStream();
    CMyComPtr<IOutStream> outFileStream = outFileStreamImpl;
    if (!outFileStreamImpl->Open(self.url.path.UTF8String)) {
        NSLog(@"can't create archive file");
        return NO;
    }
    
    CMyComPtr<IOutArchive> outArchive;
    if (CreateArchiver(&CLSIDFormat7z, &IID_IOutArchive, (void **)&outArchive) != S_OK) {
        NSLog(@"Can not get class object");
        return NO;
    }
    
    SVZ::ArchiveUpdateCallback* updateCallbackImpl = new SVZ::ArchiveUpdateCallback();
    CMyComPtr<IArchiveUpdateCallback2> updateCallback(updateCallbackImpl);
    updateCallbackImpl->PasswordIsDefined = false;
    updateCallbackImpl->Init(&dirItems);
    
    HRESULT result = outArchive->UpdateItems(outFileStream, dirItems.Size(), updateCallback);
    
    updateCallbackImpl->Finalize();
    
    if (result != S_OK) {
        NSLog(@"Update Error");
        return NO;
    }
    
    if (updateCallbackImpl->FailedFiles.Size() != 0) {
        return NO;
    }
    
    return YES;
}

@end
