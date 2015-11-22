//
//  SVZOutMemoryStream.cpp
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#include "SVZOutMemoryStream.h"

namespace SVZ {
    
    STDMETHODIMP OutMemoryStream::Write(const void* data, UInt32 size, UInt32* processedSize) {
        if (!_buffer) {
            return S_FALSE;
        }

        UInt32 clampedSize = _offset + size <= _capacity? size: (UInt32)(_capacity - _offset);
        
        memcpy(_buffer + _offset, data, clampedSize);
        _offset += clampedSize;
        if (_offset > _size) {
            _size = _offset;
        }

        if (processedSize) {
            *processedSize = clampedSize;
        }

        return S_OK;
    }
    
    STDMETHODIMP OutMemoryStream::Seek(Int64 offset, UInt32 seekOrigin, UInt64* newPosition) {
        Int64 newOffset = _offset;
        switch (seekOrigin) {
            case SEEK_SET:
                newOffset = offset;
                break;
                
            case SEEK_CUR:
                newOffset += offset;
                break;
                
            case SEEK_END:
                newOffset = _size + offset;
                break;
        }
        
        if (newOffset < 0 || newOffset > _capacity) {
            return S_FALSE;
        }
        
        _offset = newOffset;
        if (newPosition) {
            *newPosition = _offset;
        }

        return S_OK;
    }
    
    STDMETHODIMP OutMemoryStream::SetSize(UInt64 newCapacity) {
        if (newCapacity > _capacity) {
            unsigned char* newBuffer = new unsigned char[newCapacity];
            memcpy(newBuffer, _buffer, _capacity);
            delete [] _buffer;
            _buffer = newBuffer;
            _capacity = newCapacity;
        }
        return S_OK;
    }
    
    OutMemoryStream::OutMemoryStream():
        _buffer(nullptr),
        _capacity(0),
        _size(0),
        _offset(0) {
    }
    
    OutMemoryStream::~OutMemoryStream() {
        if (_buffer) {
            delete[] _buffer;
        }
    }
    
}
