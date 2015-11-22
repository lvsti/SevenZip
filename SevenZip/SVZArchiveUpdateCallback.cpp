//
//  SVZArchiveUpdateCallback.cpp
//  ObjC7z
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

    STDMETHODIMP ArchiveUpdateCallback::SetTotal(UInt64 /* size */)
    {
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::SetCompleted(const UInt64 * /* completeValue */)
    {
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetUpdateItemInfo(UInt32 /* index */,
                                                          Int32 *newData, Int32 *newProperties, UInt32 *indexInArchive)
    {
        if (newData)
            *newData = BoolToInt(true);
        if (newProperties)
            *newProperties = BoolToInt(true);
        if (indexInArchive)
            *indexInArchive = (UInt32)(Int32)-1;
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetProperty(UInt32 index, PROPID propID, PROPVARIANT *value)
    {
        NWindows::NCOM::CPropVariant prop;
        
        if (propID == kpidIsAnti)
        {
            prop = false;
            prop.Detach(value);
            return S_OK;
        }
        
        {
            const CDirItem &dirItem = (*DirItems)[index];
            switch (propID)
            {
                case kpidPath:  prop = dirItem.Name; break;
                case kpidIsDir:  prop = dirItem.isDir(); break;
                case kpidSize:  prop = dirItem.Size; break;
                case kpidAttrib:  prop = dirItem.Attrib; break;
                case kpidCTime:  prop = dirItem.CTime; break;
                case kpidATime:  prop = dirItem.ATime; break;
                case kpidMTime:  prop = dirItem.MTime; break;
            }
        }
        prop.Detach(value);
        return S_OK;
    }
    
    HRESULT ArchiveUpdateCallback::Finalize()
    {
        if (m_NeedBeClosed)
        {
            m_NeedBeClosed = false;
        }
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetStream(UInt32 index, ISequentialInStream **inStream)
    {
        RINOK(Finalize());
        
        const CDirItem &dirItem = (*DirItems)[index];
        
        if (dirItem.isDir())
            return S_OK;
        
        {
            SVZ::InFileStream *inStreamSpec = new SVZ::InFileStream();
            CMyComPtr<ISequentialInStream> inStreamLoc(inStreamSpec);
            FString path = DirPrefix + dirItem.FullPath;
            AString utf8Path;
            ConvertUnicodeToUTF8(fs2us(path), utf8Path);
            if (!inStreamSpec->Open(utf8Path.Ptr()))
            {
                DWORD sysError = ::GetLastError();
                FailedCodes.Add(sysError);
                FailedFiles.Add(path);
                // if (systemError == ERROR_SHARING_VIOLATION)
                {
                    //                PrintNewLine();
                    //                PrintError("WARNING: can't open file");
                    // PrintString(NError::MyFormatMessageW(systemError));
                    return S_FALSE;
                }
                // return sysError;
            }
            *inStream = inStreamLoc.Detach();
        }
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::SetOperationResult(Int32 /* operationResult */)
    {
        m_NeedBeClosed = true;
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetVolumeSize(UInt32 index, UInt64 *size)
    {
        if (VolumesSizes.Size() == 0)
            return S_FALSE;
        if (index >= (UInt32)VolumesSizes.Size())
            index = VolumesSizes.Size() - 1;
        *size = VolumesSizes[index];
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::GetVolumeStream(UInt32 index, ISequentialOutStream **volumeStream)
    {
        wchar_t temp[16];
        ConvertUInt32ToString(index + 1, temp);
        UString res = temp;
        while (res.Len() < 2)
            res.InsertAtFront(L'0');
        UString fileName = VolName;
        fileName += L'.';
        fileName += res;
        fileName += VolExt;
        SVZ::OutFileStream *streamImpl = new SVZ::OutFileStream();
        CMyComPtr<ISequentialOutStream> streamLoc(streamImpl);
        AString utf8Path;
        ConvertUnicodeToUTF8(fileName, utf8Path);
        if (!streamImpl->Open(utf8Path.Ptr()))
            return ::GetLastError();
        *volumeStream = streamLoc.Detach();
        return S_OK;
    }
    
    STDMETHODIMP ArchiveUpdateCallback::CryptoGetTextPassword2(Int32 *passwordIsDefined, BSTR *password)
    {
        if (!PasswordIsDefined)
        {
            if (AskPassword)
            {
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
