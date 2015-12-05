//
//  SVZStoredArchiveEntry.mm
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "SVZStoredArchiveEntry.h"
#import "SVZArchive_Private.h"
#import "SVZArchiveEntry_Private.h"
#import "SVZArchiveExtractCallback.h"
#import "SVZOutMemoryStream.h"
#import "SVZBridgedOutputStream.h"
#import "SVZUtils.h"

#include "CPP/Windows/PropVariant.h"
#include "CPP/Windows/TimeUtils.h"



@implementation SVZStoredArchiveEntry

- (instancetype)initWithIndex:(NSUInteger)aIndex
                    inArchive:(SVZArchive*)aArchive {
    NSParameterAssert(aArchive);
    NSAssert(aArchive.archive, @"uninitialized archive");
    self = [super init];
    if (self) {
        _index = aIndex;
        _archive = aArchive;
        
        [self loadPropertiesForIndex:aIndex fromArchive:aArchive];
    }
    return self;
}

- (void)loadPropertiesForIndex:(NSUInteger)aIndex fromArchive:(SVZArchive*)aArchive {
    CMyComPtr<IInArchive> archive(aArchive.archive);
    UInt32 idx = (UInt32)aIndex;

    NWindows::NCOM::CPropVariant prop;
    
    archive->GetProperty(idx, kpidPath, &prop);
    self.name = FromUString(UString(prop.bstrVal));
    
    archive->GetProperty(idx, kpidAttrib, &prop);
    self.attributes = prop.ulVal;
    
    archive->GetProperty(idx, kpidCTime, &prop);
    self.creationDate = [NSDate dateWithTimeIntervalSince1970:NWindows::NTime::FileTimeToUnixTime64(prop.filetime)];
    
    archive->GetProperty(idx, kpidMTime, &prop);
    self.modificationDate = [NSDate dateWithTimeIntervalSince1970:NWindows::NTime::FileTimeToUnixTime64(prop.filetime)];
    
    archive->GetProperty(idx, kpidATime, &prop);
    self.accessDate = [NSDate dateWithTimeIntervalSince1970:NWindows::NTime::FileTimeToUnixTime64(prop.filetime)];
    
    archive->GetProperty(idx, kpidIsDir, &prop);
    BOOL isDir = prop.boolVal;
    
    if (!isDir) {
        self.archive.archive->GetProperty(idx, kpidSize, &prop);
        self.uncompressedSize = prop.uhVal.QuadPart;
        
        self.archive.archive->GetProperty(idx, kpidPackSize, &prop);
        self.compressedSize = prop.uhVal.QuadPart;
    }
}

- (void)invalidate {
    _archive = nil;
}

- (BOOL)extractToStream:(NSOutputStream*)aOutputStream
           withPassword:(NSString*)aPassword
                  error:(NSError**)aError {
    NSParameterAssert(aOutputStream);
    SVZArchive* archive = self.archive;
    if (!archive || !archive.archive) {
        return NO;
    }
    
    SVZ::BridgedOutputStream* outStreamImpl = new SVZ::BridgedOutputStream(aOutputStream);
    CMyComPtr<ISequentialOutStream> outStream(outStreamImpl);
    
    SVZ::ArchiveExtractCallback* extractCallbackImpl = new SVZ::ArchiveExtractCallback();
    CMyComPtr<IArchiveExtractCallback> extractCallback(extractCallbackImpl);
    extractCallbackImpl->InitExtractToMemory(archive.archive, [&] (UInt32 index, UInt64 size) -> CMyComPtr<ISequentialOutStream> {
        return outStream;
    });
    
    if (aPassword) {
        extractCallbackImpl->PasswordIsDefined = true;
        extractCallbackImpl->Password = ToUString(aPassword);
    }

    UInt32 indices[] = {(UInt32)self.index};
    HRESULT result = archive.archive->Extract(indices, 1, false, extractCallback);
    if (result != S_OK || extractCallbackImpl->NumErrors > 0) {
        return NO;
    }

    return YES;
}

@end
