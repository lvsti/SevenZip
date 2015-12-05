//
//  NSFileSecurity+AsIfItWere2015.m
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 12. 05..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "NSFileSecurity+AsIfItWere2015.h"


NSUUID* NSUUIDFromCFUUID(CFUUIDRef cfUUID) {
    NSUUID* uuid = nil;
    if (cfUUID) {
        CFStringRef str = CFUUIDCreateString(NULL, cfUUID);
        uuid = [[NSUUID alloc] initWithUUIDString:(__bridge_transfer NSString*)str];
    }
    return uuid;
}

CFUUIDRef CFUUIDCreateFromNSUUID(NSUUID* uuid) {
    return CFUUIDCreateFromString(NULL, (__bridge CFStringRef)uuid.UUIDString);
}


@implementation NSFileSecurity (AsIfItWere2015)

- (mode_t)mode {
    mode_t value = 0;
    CFFileSecurityGetMode((__bridge CFFileSecurityRef)self, &value);
    return value;
}

- (void)setMode:(mode_t)mode {
    CFFileSecuritySetMode((__bridge CFFileSecurityRef)self, mode);
}

- (uid_t)owner {
    uid_t value = 0;
    CFFileSecurityGetOwner((__bridge CFFileSecurityRef)self, &value);
    return value;
}

- (void)setOwner:(uid_t)owner {
    CFFileSecuritySetOwner((__bridge CFFileSecurityRef)self, owner);
}

- (gid_t)group {
    gid_t value = 0;
    CFFileSecurityGetGroup((__bridge CFFileSecurityRef)self, &value);
    return value;
}

- (void)setGroup:(gid_t)group {
    CFFileSecuritySetGroup((__bridge CFFileSecurityRef)self, group);
}

- (NSUUID*)ownerUUID {
    CFUUIDRef cfUUID = NULL;
    CFFileSecurityCopyOwnerUUID((__bridge CFFileSecurityRef)self, &cfUUID);
    
    NSUUID* uuid = NSUUIDFromCFUUID(cfUUID);
    if (cfUUID) {
        CFRelease(cfUUID);
    }
    
    return uuid;
}

- (void)setOwnerUUID:(NSUUID*)ownerUUID {
    CFUUIDRef cfUUID = CFUUIDCreateFromNSUUID(ownerUUID);
    if (cfUUID) {
        CFFileSecuritySetOwnerUUID((__bridge CFFileSecurityRef)self, cfUUID);
        CFRelease(cfUUID);
    }
}

- (NSUUID*)groupUUID {
    CFUUIDRef cfUUID = NULL;
    CFFileSecurityCopyGroupUUID((__bridge CFFileSecurityRef)self, &cfUUID);
    
    NSUUID* uuid = NSUUIDFromCFUUID(cfUUID);
    if (cfUUID) {
        CFRelease(cfUUID);
    }
    
    return uuid;
}

- (void)setGroupUUID:(NSUUID*)groupUUID {
    CFUUIDRef cfUUID = CFUUIDCreateFromNSUUID(groupUUID);
    if (cfUUID) {
        CFFileSecuritySetGroupUUID((__bridge CFFileSecurityRef)self, cfUUID);
        CFRelease(cfUUID);
    }
}

@end
