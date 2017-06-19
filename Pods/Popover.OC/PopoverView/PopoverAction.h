//
//  PopoverAction.h
//  Popover
//
//  Created by StevenLee on 2016/12/10.
//  Copyright © 2016年 lifution. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, PopoverViewStyle) {
    PopoverViewStyleDefault = 0, // 默认风格, 白色
    PopoverViewStyleDark, // 黑色风格
};

@interface PopoverAction : NSObject

@property (nonatomic, strong, readonly) UIImage * _Nullable image; ///< 图标 (建议使用 60pix*60pix 的图片)
@property (nonatomic, copy, readonly) NSString * _Nullable title; ///< 标题
@property (nonatomic, copy, readonly) void(^ _Nullable handler)(PopoverAction * _Nullable action); ///< 选择回调, 该Block不会导致内存泄露, Block内代码无需刻意去设置弱引用.


+ (instancetype _Nonnull)actionWithTitle:(NSString *_Nullable)title handler:(void (^ _Nullable)(PopoverAction * _Nullable action))handler;

+ (instancetype _Nonnull)actionWithImage:(UIImage *_Nullable)image title:(NSString *_Nullable)title handler:(void (^ _Nullable)(PopoverAction * _Nullable action))handler;

@end
