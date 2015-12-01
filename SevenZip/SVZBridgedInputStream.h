//
//  SVZBridgedInputStream.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 26..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#ifndef SVZBridgedInputStream_h
#define SVZBridgedInputStream_h

#include "StdAfx.h"
#include "CPP/7zip/IStream.h"
#include "CPP/Common/MyCom.h"

@class NSInputStream;

namespace SVZ {
    
    class BridgedInputStream : public ISequentialInStream, public CMyUnknownImp {
    private:
        NSInputStream* _source;
        
    public:
        MY_UNKNOWN_IMP1(ISequentialInStream)
        
        STDMETHOD(Read)(void* data, UInt32 size, UInt32* processedSize);
        
        BridgedInputStream(NSInputStream* source);
        virtual ~BridgedInputStream();
    };
}

#endif /* SVZBridgedInputStream_h */
