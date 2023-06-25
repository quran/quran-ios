//
//  FixedTextNode.m
//  QuranEngineApp
//
//  Created by Mohamed Afifi on 2023-06-24.
//

#import "FixedTextNode.h"
#import <AsyncDisplayKit/ASThread.h>

@interface ASDisplayNode(Private)
- (void)displayDidFinish;
@end

@interface ASTextNode(private)
- (id)_linkAttributeValueAtPoint:(CGPoint)point
                   attributeName:(out NSString * __autoreleasing *)attributeNameOut
                           range:(out NSRange *)rangeOut
   inAdditionalTruncationMessage:(out BOOL *)inAdditionalTruncationMessageOut
                 forHighlighting:(BOOL)highlighting;
@end

@implementation FixedTextNode

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    ASDisplayNodeAssertMainThread();
    ASLockScopeSelf();

    if (!self.passthroughNonlinkTouches) {
        return [super pointInside:point withEvent:event];
    }

    if (!CGRectContainsPoint(self.bounds, point)){
        return [super pointInside:point withEvent:event];
    }

    NSRange range = NSMakeRange(0, 0);
    NSString *linkAttributeName = nil;
    BOOL inAdditionalTruncationMessage = NO;

    id linkAttributeValue = [self _linkAttributeValueAtPoint:point
                                               attributeName:&linkAttributeName
                                                       range:&range
                               inAdditionalTruncationMessage:&inAdditionalTruncationMessage
                                             forHighlighting:YES];

    NSUInteger lastCharIndex = NSIntegerMax;
    BOOL linkCrossesVisibleRange = (lastCharIndex > range.location) && (lastCharIndex < NSMaxRange(range) - 1);

    if (self.alwaysHandleTruncationTokenTap && inAdditionalTruncationMessage) {
        return YES;
    }

    if (range.length > 0 && !linkCrossesVisibleRange && linkAttributeValue != nil && linkAttributeName != nil) {
        return YES;
    } else {
        return NO;
    }
}

- (void)displayDidFinish {
    [super displayDidFinish];
    if (self.onDisplayFinished) {
        self.onDisplayFinished();
    }
}

@end
