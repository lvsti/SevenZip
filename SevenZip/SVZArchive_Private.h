//
//  SVZArchive_Private.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "SVZArchive.h"

#include "CPP/Common/MyCom.h"
#include "CPP/7zip/Archive/IArchive.h"

@interface SVZArchive ()

@property (nonatomic, assign, readwrite) CMyComPtr<IInArchive> archive;

@end
