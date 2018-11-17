//
//  JX_RichTextRenderer.h
//  JX_RichTextRendererDemo
//
//  Created by Joey Xu on 2018/11/17.
//  Copyright © 2018 Joey Xu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JX_RichTextRenderer : NSObject

/**
 Indicate the shadow size by this property. By default, the shadow has black color, and the default value of this property is CGSizeZero.
 */
@property (nonatomic, assign) CGSize shadowSize;

/**
 The copy of attributedText instance passed in initWithAttributedText: method.
 */
@property (nonatomic, strong, readonly) NSMutableAttributedString *attributedText;

/**
 Create a rich text renderer instance, which has the whole layout information of the rich text. JX_RichTextRenderer instances can be used in subthread.

 @param attributedText NSAttributedString instance.
 @param constraintSize The width and height constraints to apply when computing the string’s bounding rectangle.
 @param insets Edge insets of the output image.
 @param lineSpace Text line space.
 @return Rich text renderer instance.
 */
- (instancetype)initWithAttributedText:(NSAttributedString *)attributedText
                        constraintSize:(CGSize)constraintSize
                                insets:(UIEdgeInsets)insets
                             lineSpace:(CGFloat)lineSpace;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Trigger the CoreGraphic draw task, get an UIImage as return value. This method doesn't require main thread.

 @return an UIImage which contains the rich text.
 */
- (UIImage *)render;

/**
 @return The size of the rich text image. This method doesn't require main thread.
 */
- (CGSize)contentSize;

/**
 Given a point in the rich text image's coordinate system, it returns the character index of that touch point. This method doesn't require main thread.

 @param point A point in the rich text image's coordinate system.
 @return Character index of that touch point.
 */
- (NSInteger)characterIndexForPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
