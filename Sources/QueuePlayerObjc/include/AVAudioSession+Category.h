//
//  AVAudioSession+Category.h
//  QueuePlayer
//
//  Created by Mohamed Afifi on 9/24/18.
//  Copyright © 2018 Quran.com. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAudioSession(Category)

- (BOOL)setCategoryiO9Compatible:(nonnull AVAudioSessionCategory)category error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
