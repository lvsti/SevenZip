//
//  SVZOutFileStream.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#ifndef SVZOutFileStream_h
#define SVZOutFileStream_h

#include "StdAfx.h"

#include "FileStreams.h"

namespace SVZ {

    class OutFileStream: public IOutStream, public CMyUnknownImp {
    private:
        FILE* _file;
        
    public:
        MY_UNKNOWN_IMP1(IOutStream)
        
        STDMETHOD(Write)(const void* data, UInt32 size, UInt32* processedSize);
        STDMETHOD(Seek)(Int64 offset, UInt32 seekOrigin, UInt64* newPosition);
        STDMETHOD(SetSize)(UInt64 newSize);
        
        bool Open(const char* path);
        void Close();
        
        OutFileStream();
        virtual ~OutFileStream();
    };

}

#endif /* SVZOutFileStream_h */
