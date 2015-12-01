//
//  SVZPreamble.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

// Credits: smileyborg/Xcode7Macros.h
#if __has_feature(nullability)
#   define SVZ_ASSUME_NONNULL_BEGIN      NS_ASSUME_NONNULL_BEGIN
#   define SVZ_ASSUME_NONNULL_END        NS_ASSUME_NONNULL_END
#   define SVZ_NULLABLE                  nullable
#   define SVZ_NULLABLE_PTR              _Nullable
#   define SVZ_NONNULL                   nonnull
#else
#   define SVZ_ASSUME_NONNULL_BEGIN
#   define SVZ_ASSUME_NONNULL_END
#   define SVZ_NULLABLE
#   define SVZ_NULLABLE_PTR
#   define SVZ_NONNULL
#endif

#if __has_feature(objc_generics)
#   define SVZ_GENERIC(class, ...)      class<__VA_ARGS__>
#   define SVZ_GENERIC_TYPE(type)       type
#else
#   define SVZ_GENERIC(class, ...)      class
#   define SVZ_GENERIC_TYPE(type)       id
#endif
