//
//  SVZArchiveOpenCallback.cpp
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 21..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#include "SVZArchiveOpenCallback.h"

namespace SVZ {
    
    STDMETHODIMP ArchiveOpenCallback::SetTotal(const UInt64* /* files */, const UInt64* /* bytes */) {
        return S_OK;
    }
    
    STDMETHODIMP ArchiveOpenCallback::SetCompleted(const UInt64* /* files */, const UInt64* /* bytes */) {
        return S_OK;
    }
    
    STDMETHODIMP ArchiveOpenCallback::CryptoGetTextPassword(BSTR* password) {
        if (!PasswordIsDefined) {
            return E_ABORT;
        }

        return StringToBstr(Password, password);
    }

}