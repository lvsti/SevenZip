//
//  SVZArchiveExtractCallback.cpp
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 21..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#include "SVZArchiveExtractCallback.h"

#include "CPP/Windows/Defs.h"
#include "CPP/Windows/FileDir.h"
#include "CPP/Windows/FileFind.h"
#include "CPP/Windows/FileName.h"
#include "CPP/Windows/PropVariant.h"
#include "CPP/Windows/PropVariantConv.h"

#include "CPP/Common/UTFConvert.h"

#include "SVZOutFileStream.h"

static const wchar_t *kEmptyFileAlias = L"[Content]";

static HRESULT IsArchiveItemProp(IInArchive *archive, UInt32 index, PROPID propID, bool &result) {
    NWindows::NCOM::CPropVariant prop;
    RINOK(archive->GetProperty(index, propID, &prop));
    if (prop.vt == VT_BOOL) {
        result = VARIANT_BOOLToBool(prop.boolVal);
    }
    else if (prop.vt == VT_EMPTY) {
        result = false;
    }
    else {
        return E_FAIL;
    }
    return S_OK;
}

static HRESULT IsArchiveItemFolder(IInArchive *archive, UInt32 index, bool &result) {
    return IsArchiveItemProp(archive, index, kpidIsDir, result);
}

namespace SVZ {
    
    void ArchiveExtractCallback::InitExtractToFile(IInArchive *archiveHandler,
                                                   const FString &directoryPath) {
        _numErrors = 0;
        _archiveHandler = archiveHandler;
        _directoryPath = directoryPath;
        _extractToFile = true;
        NWindows::NFile::NName::NormalizeDirPathPrefix(_directoryPath);
    }
    
    void ArchiveExtractCallback::InitExtractToMemory(IInArchive *archiveHandler,
                                                     OutStreamProvider outStreamProvider) {
        _numErrors = 0;
        _archiveHandler = archiveHandler;
        _outStreamProvider = outStreamProvider;
        _extractToFile = false;
    }
    
    STDMETHODIMP ArchiveExtractCallback::SetTotal(UInt64 /* size */) {
        return S_OK;
    }
    
    STDMETHODIMP ArchiveExtractCallback::SetCompleted(const UInt64 * /* completeValue */) {
        return S_OK;
    }
    
    STDMETHODIMP ArchiveExtractCallback::GetStream(UInt32 index,
                                                   ISequentialOutStream **aOutStream,
                                                   Int32 askExtractMode) {
        *aOutStream = 0;
        _outStream.Release();
        
        if (askExtractMode != NArchive::NExtract::NAskMode::kExtract) {
            return S_OK;
        }

        if (_extractToFile) {
            return ExtractToFile(index, aOutStream);
        }

        return ExtractToMemory(index, aOutStream);
    }

    HRESULT ArchiveExtractCallback::ExtractToMemory(UInt32 index, ISequentialOutStream **aOutStream) {
        NWindows::NCOM::CPropVariant prop;
        RINOK(_archiveHandler->GetProperty(index, kpidSize, &prop));
        UInt64 fileSize = prop.uhVal.QuadPart;

        CMyComPtr<ISequentialOutStream> os = _outStreamProvider(index, fileSize);
        if (!os) {
            return E_ABORT;
        }
        *aOutStream = os.Detach();

        return S_OK;
    }

    HRESULT ArchiveExtractCallback::ExtractToFile(UInt32 index, ISequentialOutStream **aOutStream) {
        {
            // Get Name
            NWindows::NCOM::CPropVariant prop;
            RINOK(_archiveHandler->GetProperty(index, kpidPath, &prop));
            
            UString fullPath;
            if (prop.vt == VT_EMPTY) {
                fullPath = kEmptyFileAlias;
            }
            else {
                if (prop.vt != VT_BSTR) {
                    return E_FAIL;
                }
                fullPath = prop.bstrVal;
            }
            _filePath = fullPath;
        }

        {
            // Get Attrib
            NWindows::NCOM::CPropVariant prop;
            RINOK(_archiveHandler->GetProperty(index, kpidAttrib, &prop));
            if (prop.vt == VT_EMPTY) {
                _processedFileInfo.attrib = 0;
                _processedFileInfo.attribDefined = false;
            }
            else {
                if (prop.vt != VT_UI4)
                    return E_FAIL;
                _processedFileInfo.attrib = prop.ulVal;
                _processedFileInfo.attribDefined = true;
            }
        }
        
        RINOK(IsArchiveItemFolder(_archiveHandler, index, _processedFileInfo.isDir));
        
        {
            // Get Modified Time
            NWindows::NCOM::CPropVariant prop;
            RINOK(_archiveHandler->GetProperty(index, kpidMTime, &prop));
            _processedFileInfo.mTimeDefined = false;
            switch (prop.vt) {
                case VT_EMPTY:
                    // _processedFileInfo.MTime = _utcMTimeDefault;
                    break;
                case VT_FILETIME:
                    _processedFileInfo.mTime = prop.filetime;
                    _processedFileInfo.mTimeDefined = true;
                    break;
                default:
                    return E_FAIL;
            }
            
        }
        {
            // Get Size
            NWindows::NCOM::CPropVariant prop;
            RINOK(_archiveHandler->GetProperty(index, kpidSize, &prop));
            UInt64 newFileSize;
            /* bool newFileSizeDefined = */ ConvertPropVariantToUInt64(prop, newFileSize);
        }
        
        
        {
            // Create folders for file
            int slashPos = _filePath.ReverseFind_PathSepar();
            if (slashPos >= 0) {
                NWindows::NFile::NDir::CreateComplexDir(_directoryPath + us2fs(_filePath.Left(slashPos)));
            }
        }
        
        FString fullProcessedPath = _directoryPath + us2fs(_filePath);
        _diskFilePath = fullProcessedPath;
        
        if (_processedFileInfo.isDir) {
            NWindows::NFile::NDir::CreateComplexDir(fullProcessedPath);
        }
        else {
            NWindows::NFile::NFind::CFileInfo fi;
            if (fi.Find(fullProcessedPath)) {
                if (!NWindows::NFile::NDir::DeleteFileAlways(fullProcessedPath)) {
//                    PrintError("Can not delete output file", fullProcessedPath);
                    return E_ABORT;
                }
            }
            
            _outFileStreamImpl = new OutFileStream();
            CMyComPtr<ISequentialOutStream> outStreamLoc(_outFileStreamImpl);
            AString utf8Path;
            ConvertUnicodeToUTF8(fs2us(fullProcessedPath), utf8Path);
            if (!_outFileStreamImpl->Open(utf8Path.Ptr())) {
//                PrintError("Can not open output file", fullProcessedPath);
                return E_ABORT;
            }
            _outStream = outStreamLoc;
            *aOutStream = outStreamLoc.Detach();
        }
        return S_OK;
    }
    
    STDMETHODIMP ArchiveExtractCallback::PrepareOperation(Int32 askExtractMode) {
        _extractMode = false;
        switch (askExtractMode) {
            case NArchive::NExtract::NAskMode::kExtract:  _extractMode = true; break;
        }
        return S_OK;
    }
    
    STDMETHODIMP ArchiveExtractCallback::SetOperationResult(Int32 operationResult) {
        switch (operationResult) {
            case NArchive::NExtract::NOperationResult::kOK:
                break;
            default: {
                ++_numErrors;
            }
        }
        
        if (_extractToFile) {
            if (_outFileStreamImpl) {
    //            if (_processedFileInfo.MTimeDefined) {
    //                _outFileStreamImpl->SetMTime(&_processedFileInfo.MTime);
    //            }
                _outFileStreamImpl->Close();
                _outFileStreamImpl = nullptr;
            }
            
            if (_extractMode && _processedFileInfo.attribDefined) {
                NWindows::NFile::NDir::SetFileAttrib(_diskFilePath, _processedFileInfo.attrib);
            }
        }

        _outStream.Release();

        return S_OK;
    }
    
    
    STDMETHODIMP ArchiveExtractCallback::CryptoGetTextPassword(BSTR *aPassword) {
        if (!passwordIsDefined) {
            return E_ABORT;
        }
        return StringToBstr(password, aPassword);
    }
    
}
