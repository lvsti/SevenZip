//
//  SVZArchiveUpdateCallback.cpp
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#include "SVZArchiveUpdateCallback.h"

#include "Defs.h"
#include "FileStreams.h"
#include "IntToString.h"
#include "MethodProps.h"
#include "CPP/Common/UTFConvert.h"

#include "SVZInFileStream.h"
#include "SVZOutFileStream.h"

namespace SVZ {

    STDMETHODIMP ArchiveUpdateCallback::SetTotal(UInt64 /* size */) {
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::SetCompleted(const UInt64 * /* completeValue */) {
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetUpdateItemInfo(UInt32 index,
                                                          Int32 *newData,
                                                          Int32 *newProperties,
                                                          UInt32 *indexInArchive) {
        const ArchiveItem &item = (*ArchiveItems)[index];
        bool isNewItem = item.CurrentIndex == ArchiveItem::kNewItemIndex;
        
        if (newData) {
            *newData = BoolToInt(isNewItem);
        }
        if (newProperties) {
            *newProperties = BoolToInt(isNewItem);
        }
        if (indexInArchive) {
            *indexInArchive = (UInt32)item.CurrentIndex;
        }
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetProperty(UInt32 index, PROPID propID, PROPVARIANT *value) {
        NWindows::NCOM::CPropVariant prop;
        
        if (propID == kpidIsAnti) {
            prop = false;
            prop.Detach(value);
            return S_OK;
        }
        
        const ArchiveItem &item = (*ArchiveItems)[index];
        switch (propID) {
            case kpidPath: prop = item.Name; break;
            case kpidIsDir: prop = item.IsDir; break;
            case kpidSize: prop = item.Size; break;
            case kpidAttrib: prop = item.Attrib; break;
            case kpidCTime: prop = item.CTime; break;
            case kpidATime: prop = item.ATime; break;
            case kpidMTime: prop = item.MTime; break;
        }

        prop.Detach(value);
        return S_OK;
    }
    
    HRESULT ArchiveUpdateCallback::Finalize() {
        if (m_NeedBeClosed) {
            m_NeedBeClosed = false;
        }
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetStream(UInt32 aIndex, ISequentialInStream **aInStream) {
        RINOK(Finalize());
        
        const ArchiveItem& item = (*ArchiveItems)[aIndex];
        
        if (item.IsDir) {
            return S_OK;
        }
        
        {
            SVZ::InFileStream *inStreamImpl = new SVZ::InFileStream();
            CMyComPtr<ISequentialInStream> inStreamLoc(inStreamImpl);
            FString path = DirPrefix + item.FullPath;
            AString utf8Path;
            ConvertUnicodeToUTF8(fs2us(path), utf8Path);
            if (!inStreamImpl->Open(utf8Path.Ptr())) {
                DWORD sysError = ::GetLastError();
                FailedCodes.Add(sysError);
                FailedFiles.Add(path);
                return sysError;
            }
            *inStream = inStreamLoc.Detach();
        }
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::SetOperationResult(Int32 /* operationResult */) {
        m_NeedBeClosed = true;
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetVolumeSize(UInt32 index, UInt64 *size) {
        if (VolumesSizes.Size() == 0) {
            return S_FALSE;
        }
        if (index >= (UInt32)VolumesSizes.Size()) {
            index = VolumesSizes.Size() - 1;
        }
        *size = VolumesSizes[index];
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetVolumeStream(UInt32 index, ISequentialOutStream **volumeStream) {
        wchar_t temp[16];
        ConvertUInt32ToString(index + 1, temp);
        UString res = temp;
        while (res.Len() < 2) {
            res.InsertAtFront(L'0');
        }
        UString fileName = VolName;
        fileName += L'.';
        fileName += res;
        fileName += VolExt;
        SVZ::OutFileStream *outFileStreamImpl = new SVZ::OutFileStream();
        CMyComPtr<ISequentialOutStream> outStream(outFileStreamImpl);
        AString utf8Path;
        ConvertUnicodeToUTF8(fileName, utf8Path);
        if (!outFileStreamImpl->Open(utf8Path.Ptr())) {
            return ::GetLastError();
        }
        *volumeStream = outStream.Detach();
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::CryptoGetTextPassword2(Int32 *passwordIsDefined, BSTR *password) {
        if (!PasswordIsDefined) {
            if (AskPassword) {
                // You can ask real password here from user
                // Password = GetPassword(OutStream);
                // PasswordIsDefined = true;
                //            PrintError("Password is not defined");
                return E_ABORT;
            }
        }
        *passwordIsDefined = BoolToInt(PasswordIsDefined);
        return StringToBstr(Password, password);
    }

}
