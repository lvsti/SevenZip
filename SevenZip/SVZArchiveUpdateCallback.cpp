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
        const ArchiveItem &item = (*_archiveItems)[index];
        bool isNewItem = item.currentIndex == ArchiveItem::kNewItemIndex;
        
        if (newData) {
            *newData = BoolToInt(isNewItem);
        }
        if (newProperties) {
            *newProperties = BoolToInt(isNewItem);
        }
        if (indexInArchive) {
            *indexInArchive = (UInt32)item.currentIndex;
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
        
        const ArchiveItem &item = (*_archiveItems)[index];
        switch (propID) {
            case kpidPath: prop = item.name; break;
            case kpidIsDir: prop = item.isDir; break;
            case kpidSize: prop = item.size; break;
            case kpidAttrib: prop = item.attrib; break;
            case kpidCTime: prop = item.cTime; break;
            case kpidATime: prop = item.aTime; break;
            case kpidMTime: prop = item.mTime; break;
        }

        prop.Detach(value);
        return S_OK;
    }
    
    HRESULT ArchiveUpdateCallback::Finalize() {
        if (_needBeClosed) {
            _needBeClosed = false;
        }
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetStream(UInt32 aIndex, ISequentialInStream **aInStream) {
        RINOK(Finalize());
        
        const ArchiveItem& item = (*_archiveItems)[aIndex];
        
        if (item.isDir) {
            return S_OK;
        }
        
        CMyComPtr<ISequentialInStream> inStream = _streamProvider(item.id);
        if (!inStream) {
            _failedFiles.Add(item.name);
            DWORD sysError = ::GetLastError();
            _failedCodes.Add(sysError);
            return E_FAIL;
        }
        
        *aInStream = inStream.Detach();
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::SetOperationResult(Int32 /* operationResult */) {
        _needBeClosed = true;
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetVolumeSize(UInt32 index, UInt64 *size) {
        if (volumesSizes.Size() == 0) {
            return S_FALSE;
        }
        if (index >= (UInt32)volumesSizes.Size()) {
            index = volumesSizes.Size() - 1;
        }
        *size = volumesSizes[index];
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetVolumeStream(UInt32 index, ISequentialOutStream **volumeStream) {
        wchar_t temp[16];
        ConvertUInt32ToString(index + 1, temp);
        UString res = temp;
        while (res.Len() < 2) {
            res.InsertAtFront(L'0');
        }
        UString fileName = volName;
        fileName += L'.';
        fileName += res;
        fileName += volExt;
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
    
    STDMETHODIMP ArchiveUpdateCallback::CryptoGetTextPassword2(Int32 *aPasswordIsDefined, BSTR *aPassword) {
        *aPasswordIsDefined = BoolToInt(passwordIsDefined);
        if (!passwordIsDefined) {
            return S_OK;
        }
        return StringToBstr(password, aPassword);
    }

}
