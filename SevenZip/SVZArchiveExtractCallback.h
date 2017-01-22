//
//  SVZArchiveExtractCallback.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 21..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#ifndef SVZArchiveExtractCallback_h
#define SVZArchiveExtractCallback_h

#include <functional>

#include "StdAfx.h"

#include "CPP/7zip/Archive/IArchive.h"
#include "CPP/7zip/IPassword.h"
#include "CPP/Common/MyCom.h"
#include "CPP/Common/MyString.h"
#include "CPP/Common/MyWindows.h"

namespace SVZ {
    
    class OutFileStream;
    
    typedef std::function<CMyComPtr<ISequentialOutStream>(UInt32 /*index*/, UInt64 /*filesize*/)> OutStreamProvider;
    
    class ArchiveExtractCallback: public IArchiveExtractCallback,
                                  public ICryptoGetTextPassword,
                                  public CMyUnknownImp {
    public:
        MY_UNKNOWN_IMP1(ICryptoGetTextPassword)
        
        // IProgress
        STDMETHOD(SetTotal)(UInt64 size);
        STDMETHOD(SetCompleted)(const UInt64 *completeValue);
        
        // IArchiveExtractCallback
        STDMETHOD(GetStream)(UInt32 index, ISequentialOutStream **outStream, Int32 askExtractMode);
        STDMETHOD(PrepareOperation)(Int32 askExtractMode);
        STDMETHOD(SetOperationResult)(Int32 resultEOperationResult);
        
        // ICryptoGetTextPassword
        STDMETHOD(CryptoGetTextPassword)(BSTR *aPassword);
        
    private:
        CMyComPtr<IInArchive> _archiveHandler;
        FString _directoryPath;  // Output directory
        UString _filePath;       // name inside arcvhive
        FString _diskFilePath;   // full path to file on disk
        bool _extractMode;
        struct CProcessedFileInfo
        {
            FILETIME mTime;
            UInt32 attrib;
            bool isDir;
            bool attribDefined;
            bool mTimeDefined;
        } _processedFileInfo;
        
        bool _extractToFile;
        OutFileStream* _outFileStreamImpl;
        OutStreamProvider _outStreamProvider;
        CMyComPtr<ISequentialOutStream> _outStream;
        UInt64 _numErrors;
        
        HRESULT ExtractToFile(UInt32 index, ISequentialOutStream **aOutStream);
        HRESULT ExtractToMemory(UInt32 index, ISequentialOutStream **aOutStream);

    public:
        void InitExtractToFile(IInArchive *archiveHandler,
                               const FString &directoryPath);
        void InitExtractToMemory(IInArchive *archiveHandler,
                                 OutStreamProvider outStreamProvider);
        
        const UInt64 NumErrors() const { return _numErrors; }
        
        bool passwordIsDefined;
        UString password;
        
        ArchiveExtractCallback() : passwordIsDefined(false) {}
    };
    
}

#endif /* SVZArchiveExtractCallback_h */
