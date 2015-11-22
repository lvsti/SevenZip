//
//  SVZInFileStream.cpp
//  ObjC7z
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#include "SVZInFileStream.h"

namespace SVZ {
    
    STDMETHODIMP InFileStream::Read(void* data, UInt32 size, UInt32* processedSize) {
        if (!_file) {
            return S_FALSE;
        }
        
        if (size == 0) {
            if (processedSize) {
                *processedSize = 0;
            }
            return S_OK;
        }
        
        size_t byteCount = fread(data, 1, size, _file);
        if (processedSize) {
            *processedSize = (UInt32)byteCount;
        }
        
        return S_OK;
    }
    
    STDMETHODIMP InFileStream::Seek(Int64 offset, UInt32 seekOrigin, UInt64* newPosition) {
        if (fseeko(_file, offset, seekOrigin) != 0) {
            return S_FALSE;
        }

        if (newPosition) {
            *newPosition = ftello(_file);
        }
        return S_OK;
    }
    
    bool InFileStream::Open(const char *path) {
        if (path) {
            _file = fopen(path, "rb");
        }
        return (_file != nullptr);
    }
    
    void InFileStream::Close() {
        if (_file) {
            fclose(_file);
            _file = nullptr;
        }
    }
    
    InFileStream::InFileStream(): _file(nullptr) {
    }
    
    InFileStream::~InFileStream() {
        Close();
    }
    
}
