//
//  SVZBridgedInputStream.mm
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 26..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVZBridgedInputStream.h"

namespace SVZ {

    STDMETHODIMP BridgedInputStream::Read(void* data, UInt32 size, UInt32* processedSize) {
        @autoreleasepool {
            NSInteger bytesRead = [_source read:(uint8_t*)data maxLength:size];
            if (bytesRead < 0) {
                // stream error
                if (processedSize) {
                    *processedSize = 0;
                }
                return E_FAIL;
            }
            
            if (processedSize) {
                *processedSize = (UInt32)bytesRead;
            }
        }

        return S_OK;
    }
    
    BridgedInputStream::BridgedInputStream(NSInputStream* source): _source(source) {
        @autoreleasepool {
            [_source open];
        }
    }
    
    BridgedInputStream::~BridgedInputStream() {
        @autoreleasepool {
            [_source close];
        }
        _source = nil;
    }
}
