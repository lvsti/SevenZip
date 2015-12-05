//
//  NSFileSecurity+AsIfItWere2015.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 12. 05..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileSecurity (AsIfItWere2015)

@property (nonatomic, assign, readwrite) mode_t mode;
@property (nonatomic, assign, readwrite) uid_t owner;
@property (nonatomic, assign, readwrite) gid_t group;
@property (nonatomic, copy, readwrite) NSUUID* ownerUUID;
@property (nonatomic, copy, readwrite) NSUUID* groupUUID;

@end
