//
//  SVZBridgedOutputStream.m
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 12. 01..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVZBridgedOutputStream.h"

namespace SVZ {
    
    STDMETHODIMP BridgedOutputStream::Write(const void* data, UInt32 size, UInt32* processedSize) {
        @autoreleasepool {
            if (!_drain.hasSpaceAvailable) {
                if (processedSize) {
                    *processedSize = 0;
                }
                return E_FAIL;
            }
            
            NSInteger bytesWritten = [_drain write:(const uint8_t*)data maxLength:size];
            if (bytesWritten < 0) {
                // stream error
                if (processedSize) {
                    *processedSize = 0;
                }
                return E_FAIL;
            }
            
            if (processedSize) {
                *processedSize = (UInt32)bytesWritten;
            }
        }
        
        return S_OK;
    }

    BridgedOutputStream::BridgedOutputStream(NSOutputStream* drain): _drain(drain) {
        @autoreleasepool {
            [_drain open];
        }
    }
    
    BridgedOutputStream::~BridgedOutputStream() {
        @autoreleasepool {
            [_drain close];
        }
    }

}
