//
//  FixedTextNode.h
//  QuranEngineApp
//
//  Created by Mohamed Afifi on 2023-06-24.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASTextNode.h>

NS_ASSUME_NONNULL_BEGIN

// Workaround until https://github.com/TextureGroup/Texture/pull/1790 is merged
@interface FixedTextNode : ASTextNode


@property (copy, nullable) void (^onDisplayFinished)(void);

@end

NS_ASSUME_NONNULL_END
