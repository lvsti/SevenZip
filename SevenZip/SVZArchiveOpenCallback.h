//
//  SVZArchiveOpenCallback.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 21..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#ifndef SVZArchiveOpenCallback_h
#define SVZArchiveOpenCallback_h

#include "IArchive.h"
#include "IPassword.h"
#include "MyCom.h"
#include "MyString.h"
#include "MyWindows.h"

namespace SVZ {

    class ArchiveOpenCallback: public IArchiveOpenCallback,
                               public ICryptoGetTextPassword,
                               public CMyUnknownImp {
    public:
        MY_UNKNOWN_IMP1(ICryptoGetTextPassword)
        
        STDMETHOD(SetTotal)(const UInt64* files, const UInt64* bytes);
        STDMETHOD(SetCompleted)(const UInt64* files, const UInt64* bytes);
        
        STDMETHOD(CryptoGetTextPassword)(BSTR *password);

    public:
        bool passwordIsDefined;
        UString password;
        
    public:
        ArchiveOpenCallback() : passwordIsDefined(false) {}
        bool DidAskForPassword() const { return _didAskForPassword; }
        
    private:
        bool _didAskForPassword;
    };

}

#endif /* SVZArchiveOpenCallback_h */
