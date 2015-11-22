//
//  SVZInFileStream.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#ifndef SVZInFileStream_h
#define SVZInFileStream_h

#include "StdAfx.h"

#include "FileStreams.h"

namespace SVZ {
    
    class InFileStream : public IInStream, public CMyUnknownImp {
    private:
        FILE* _file;
        
    public:
        MY_UNKNOWN_IMP1(IInStream)
        
        STDMETHOD(Seek)(Int64 offset, UInt32 seekOrigin, UInt64* newPosition);
        STDMETHOD(Read)(void* data, UInt32 size, UInt32* processedSize);
        
        bool Open(const char* path);
        void Close();
        
        InFileStream();
        virtual ~InFileStream();
    };
}

#endif /* SVZInFileStream_h */
