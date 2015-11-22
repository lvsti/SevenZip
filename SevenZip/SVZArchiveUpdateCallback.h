//
//  SVZArchiveUpdateCallback.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#ifndef SVZArchiveUpdateCallback_h
#define SVZArchiveUpdateCallback_h

#include "StdAfx.h"

#include "IArchive.h"
#include "IPassword.h"
#include "MyCom.h"
#include "MyString.h"
#include "MyWindows.h"

namespace SVZ {

    struct CDirItem
    {
        UInt64 Size;
        FILETIME CTime;
        FILETIME ATime;
        FILETIME MTime;
        UString Name;
        FString FullPath;
        UInt32 Attrib;
        
        bool isDir() const { return (Attrib & FILE_ATTRIBUTE_DIRECTORY) != 0 ; }
    };
    
    class ArchiveUpdateCallback: public IArchiveUpdateCallback2,
    public ICryptoGetTextPassword2,
    public CMyUnknownImp
    {
    public:
        MY_UNKNOWN_IMP2(IArchiveUpdateCallback2, ICryptoGetTextPassword2)
        
        // IProgress
        STDMETHOD(SetTotal)(UInt64 size);
        STDMETHOD(SetCompleted)(const UInt64 *completeValue);
        
        // IUpdateCallback2
        STDMETHOD(GetUpdateItemInfo)(UInt32 index,
                                     Int32 *newData, Int32 *newProperties, UInt32 *indexInArchive);
        STDMETHOD(GetProperty)(UInt32 index, PROPID propID, PROPVARIANT *value);
        STDMETHOD(GetStream)(UInt32 index, ISequentialInStream **inStream);
        STDMETHOD(SetOperationResult)(Int32 operationResult);
        STDMETHOD(GetVolumeSize)(UInt32 index, UInt64 *size);
        STDMETHOD(GetVolumeStream)(UInt32 index, ISequentialOutStream **volumeStream);
        
        STDMETHOD(CryptoGetTextPassword2)(Int32 *passwordIsDefined, BSTR *password);
        
    public:
        CRecordVector<UInt64> VolumesSizes;
        UString VolName;
        UString VolExt;
        
        FString DirPrefix;
        const CObjectVector<CDirItem> *DirItems;
        
        bool PasswordIsDefined;
        UString Password;
        bool AskPassword;
        
        bool m_NeedBeClosed;
        
        FStringVector FailedFiles;
        CRecordVector<HRESULT> FailedCodes;
        
        ArchiveUpdateCallback(): PasswordIsDefined(false), AskPassword(false), DirItems(0) {};
        
        ~ArchiveUpdateCallback() { Finalize(); }
        HRESULT Finalize();
        
        void Init(const CObjectVector<CDirItem> *dirItems)
        {
            DirItems = dirItems;
            m_NeedBeClosed = false;
            FailedFiles.Clear();
            FailedCodes.Clear();
        }
    };

}

#endif /* SVZArchiveUpdateCallback_h */
