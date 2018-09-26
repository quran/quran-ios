//
//  AVAudioSession+Category.m
//  QueuePlayer
//
//  Created by Mohamed Afifi on 9/24/18.
//  Copyright © 2018 Quran.com. All rights reserved.
//

#import "AVAudioSession+Category.h"

@implementation AVAudioSession(Category)

- (BOOL)setCategoryiO9Compatible:(nonnull AVAudioSessionCategory)category error:(NSError **)error {
    return [self setCategory:category error:error];
}
@end
