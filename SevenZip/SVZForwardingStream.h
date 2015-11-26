//
//  SVZForwardingStream.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 26..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#ifndef SVZForwardingStream_h
#define SVZForwardingStream_h

#include "StdAfx.h"
#include "CPP/7zip/IStream.h"
#include "CPP/Common/MyCom.h"

@class NSInputStream;

namespace SVZ {
    
    class ForwardingStream : public ISequentialInStream, public CMyUnknownImp {
    private:
        NSInputStream* _source;
        
    public:
        MY_UNKNOWN_IMP1(ISequentialInStream)
        
        STDMETHOD(Read)(void* data, UInt32 size, UInt32* processedSize);
        
        ForwardingStream(NSInputStream* source);
        virtual ~ForwardingStream();
    };
}

#endif /* SVZForwardingStream_h */
