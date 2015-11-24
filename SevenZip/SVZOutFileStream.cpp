//
//  SVZOutFileStream.cpp
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#include "SVZOutFileStream.h"

namespace SVZ {
    
    STDMETHODIMP OutFileStream::Write(const void* data, UInt32 size, UInt32* processedSize) {
        if (!_file) {
            return S_FALSE;
        }
        
        size_t byteCount = fwrite(data, 1, size, _file);
        if (processedSize) {
            *processedSize = (UInt32)byteCount;
        }

        return S_OK;
    }
    
    STDMETHODIMP OutFileStream::Seek(Int64 offset, UInt32 seekOrigin, UInt64* newPosition) {
        if (!_file) {
            return S_FALSE;
        }

        if (fseeko(_file, offset, seekOrigin) != 0) {
            return S_FALSE;
        }

        if (newPosition) {
            *newPosition = ftello(_file);
        }

        return S_OK;
    }
    
    STDMETHODIMP OutFileStream::SetSize(UInt64 newSize) {
        return S_OK;
    }
    
    bool OutFileStream::Open(const char* path, bool overwriteExisting) {
        _file = fopen(path, overwriteExisting? "w+b": "r+b");
        if (!_file) {
            _file = fopen(path, "w+b");
        }
        return (_file != nullptr);
    }
    
    void OutFileStream::Close() {
        if (_file) {
            fclose(_file);
            _file = nullptr;
        }
    }
    
    OutFileStream::OutFileStream(): _file(nullptr) {
    }
    
    OutFileStream::~OutFileStream() {
        Close();
    }
    
}

