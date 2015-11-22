//
//  SVZOutMemoryStream.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#ifndef SVZOutMemoryStream_h
#define SVZOutMemoryStream_h

#include "StdAfx.h"

#include "CPP/Common/MyCom.h"
#include "CPP/7zip/IStream.h"

namespace SVZ {
    
    class OutMemoryStream: public IOutStream, public CMyUnknownImp {
    private:
        unsigned char* _buffer;
        UInt64 _capacity;
        UInt64 _size;
        UInt64 _offset;
        
    public:
        MY_UNKNOWN_IMP1(IOutStream)
        
        STDMETHOD(Write)(const void* data, UInt32 size, UInt32* processedSize);
        STDMETHOD(Seek)(Int64 offset, UInt32 seekOrigin, UInt64* newPosition);
        STDMETHOD(SetSize)(UInt64 newSize);

        const unsigned char* Buffer() const { return _buffer; }
        UInt64 Size() const { return _size; }
        void SetCapacity(UInt64 capacity);
        
        OutMemoryStream(UInt64 capacity = 0);
        virtual ~OutMemoryStream();
    };
    
}

#endif /* SVZOutMemoryStream_h */
