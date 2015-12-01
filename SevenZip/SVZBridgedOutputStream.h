//
//  SVZBridgedOutputStream.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 12. 01..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#ifndef SVZBridgedOutputStream_h
#define SVZBridgedOutputStream_h

#include "StdAfx.h"
#include "CPP/7zip/IStream.h"
#include "CPP/Common/MyCom.h"

@class NSOutputStream;

namespace SVZ {
    
    class BridgedOutputStream : public ISequentialOutStream, public CMyUnknownImp {
    private:
        NSOutputStream* _drain;
        
    public:
        MY_UNKNOWN_IMP1(ISequentialOutStream)

        STDMETHOD(Write)(const void *data, UInt32 size, UInt32 *processedSize);
        
        BridgedOutputStream(NSOutputStream* drain);
        virtual ~BridgedOutputStream();
    };
}

#endif /* SVZBridgedOutputStream_h */
