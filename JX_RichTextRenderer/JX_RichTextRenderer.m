//
//  JX_RichTextRenderer.m
//  JX_RichTextRendererDemo
//
//  Created by Joey Xu on 2018/11/17.
//  Copyright © 2018 Joey Xu. All rights reserved.
//

#import "JX_RichTextRenderer.h"
#import <CoreText/CoreText.h>

@interface QGAttachmentData : NSObject
@property (nonatomic, strong) NSTextAttachment *attachment;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGRect drawRect;
@property (nonatomic, assign) CGRect imageFrame;
@property (nonatomic, assign) NSUInteger location;
@end

@implementation QGAttachmentData

@end

@interface JX_RichTextRenderer ()
@property (nonatomic, assign) CGSize constraintSize;
@property (nonatomic, assign) UIEdgeInsets insets;
@property (nonatomic, assign) CGFloat lineSpace;

@property (nonatomic, assign) CTFrameRef ctFrame;

@property (nonatomic, assign) CGFloat maxLineHeight;
@property (nonatomic, assign) CGFloat maxLineWidth;
@property (nonatomic, assign) CGFloat maxAscent;
@property (nonatomic, assign) CGFloat maxDescent;
@property (nonatomic, assign) CGRect bounds;
@property (nonatomic, strong) NSMutableArray<QGAttachmentData *> *attachmentDatas;
@end

@implementation JX_RichTextRenderer

/* Callbacks */
static void deallocCallback(void* ref ){
    
}
static CGFloat ascentCallback( void *ref ){
#ifdef CGFLOAT_IS_DOUBLE
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"ascent"] doubleValue];
#else
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"ascent"] floatValue];
#endif
}
static CGFloat descentCallback( void *ref ){
#ifdef CGFLOAT_IS_DOUBLE
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"descent"] doubleValue];
#else
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"descent"] floatValue];
#endif
}
static CGFloat widthCallback( void* ref ){
#ifdef CGFLOAT_IS_DOUBLE
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"width"] doubleValue];
#else
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"width"] floatValue];
#endif
}

- (instancetype)initWithAttributedText:(NSAttributedString *)attributedText
                        constraintSize:(CGSize)constraintSize
                                insets:(UIEdgeInsets)insets
                             lineSpace:(CGFloat)lineSpace {
    self = [super init];
    if (self) {
        _attributedText = [attributedText mutableCopy];
        _constraintSize = CGSizeMake(MIN(constraintSize.width, 10000), MIN(constraintSize.height, 10000));
        _insets = insets;
        _lineSpace = lineSpace;
        _shadowSize = CGSizeZero;
        _attachmentDatas = [NSMutableArray new];
        
        [self configRunDelegateForAttributedString:_attributedText];
        _ctFrame = [self createCTFrame];
        [self calculateLayoutForCTFrame:_ctFrame];
    }
    return self;
}

- (void)dealloc {
    CFRelease(_ctFrame);
}

- (UIImage *)render {
    UIGraphicsBeginImageContextWithOptions(_bounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // ctFrame是根据pathBox来绘制的
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextTranslateCTM(context, 0, -self.constraintSize.height);
    
    if (!CGSizeEqualToSize(self.shadowSize, CGSizeZero)) {
        CGContextSetShadowWithColor(context, self.shadowSize, 0, [UIColor blackColor].CGColor);
    }
    
    CFArrayRef ctLines = CTFrameGetLines(self.ctFrame);
    CFIndex lineCount = CFArrayGetCount(ctLines);
    for (NSUInteger i = 0; i < lineCount; i++) {
        CTLineRef ctLine = CFArrayGetValueAtIndex(ctLines, i);
        CGContextSetTextPosition(context, self.insets.left, self.constraintSize.height - self.insets.top - _maxAscent - i*(_maxLineHeight+self.lineSpace));
        CTLineDraw(ctLine, context);
    }
    
    [self.attachmentDatas enumerateObjectsUsingBlock:^(QGAttachmentData * _Nonnull attachmentData, NSUInteger idx, BOOL * _Nonnull stop) {
        CGContextDrawImage(context, attachmentData.drawRect, attachmentData.image.CGImage);
    }];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (CGSize)contentSize {
    return _bounds.size;
}

- (NSInteger)characterIndexForPoint:(CGPoint)point {
    CGPoint reversePoint = CGPointMake(point.x, self.constraintSize.height - point.y);
    
    NSUInteger lineIndex = 0;
    if (point.y > self.insets.top) {
#ifdef CGFLOAT_IS_DOUBLE
        lineIndex = floor((point.y - self.insets.top)/_maxLineHeight);
#else
        lineIndex = floorf((point.y - self.insets.top)/_maxLineHeight);
#endif
    }
    
    CFArrayRef ctLines = CTFrameGetLines(_ctFrame);
    CFIndex count = CFArrayGetCount(ctLines);
    if (count <= 0 || lineIndex > count-1) {
        return NSNotFound;
    }
    CTLineRef ctLine = CFArrayGetValueAtIndex(ctLines, lineIndex);
    if (ctLine == NULL) {
        return NSNotFound;
    }
    NSInteger index = CTLineGetStringIndexForPosition(ctLine, reversePoint);
    return index;
}

- (void)configRunDelegateForAttributedString:(NSMutableAttributedString *)attributedString {
    //render empty space for drawing the image in the text //1
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.getAscent = ascentCallback;
    callbacks.getDescent = descentCallback;
    callbacks.getWidth = widthCallback;
    callbacks.dealloc = deallocCallback;
    __block UIFont *maxFont = nil;
    [attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length)
                                         options:0
                                      usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
                                          UIFont *font = attrs[NSFontAttributeName];
                                          if (!font) return;
                                          if (!maxFont || (maxFont.lineHeight < font.lineHeight)) {
                                              maxFont = font;
                                          }
                                      }];
    [attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length)
                                         options:0
                                      usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
                                          NSTextAttachment *attachment = attrs[NSAttachmentAttributeName];
                                          if (attachment) {
                                              NSDictionary* imgAttr;
                                              if (maxFont) {
                                                  CGFloat fontAbsoluteDescender = -maxFont.descender;//descender是负数
                                                  CGFloat centerYOffset = (maxFont.ascender+fontAbsoluteDescender)/2 - fontAbsoluteDescender;
                                                  CGFloat ascent = attachment.bounds.size.height/2+centerYOffset;
                                                  CGFloat descender = -(attachment.bounds.size.height-ascent);
                                                  CGFloat maxDescentOfRun = MAX(fontAbsoluteDescender, -descender);
                                                  self.maxDescent = MAX(self.maxDescent, maxDescentOfRun);
                                                  imgAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                                                             @(attachment.bounds.size.width), @"width",
                                                             @(ascent), @"ascent",
                                                             @(descender), @"descent",
                                                             nil];
                                              } else {
                                                  imgAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                                                             @(attachment.bounds.size.width), @"width",
                                                             @(attachment.bounds.size.height), @"ascent",
                                                             @(0), @"descent",
                                                             nil];
                                                  self.maxDescent = 0;
                                                  NSAssert(0, @"AttributedString's font is nil!");
                                              }
                                              
                                              CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void * _Nullable)(imgAttr));
                                              [attributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id _Nonnull)(delegate) range:range];
                                              CFRelease(delegate);
                                              
                                              for (NSUInteger i = 0; i < range.length; i++) {
                                                  QGAttachmentData *attachmentData = [QGAttachmentData new];
                                                  attachmentData.location = range.location + i;
                                                  attachmentData.image = attachment.image;
                                                  attachmentData.attachment = attachment;
                                                  [self.attachmentDatas addObject:attachmentData];
                                              }
                                          }
                                      }];
}

- (CTFrameRef)createCTFrame {
    CGRect pathBox = CGRectMake(0, 0, self.constraintSize.width, self.constraintSize.height);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, pathBox);
    
    NSMutableAttributedString *attributedText = self.attributedText;
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedText);
    CTFrameRef ctFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, [attributedText length]), path, NULL);
    
    CFRelease(path);
    CFRelease(frameSetter);
    
    return ctFrame;
}

- (void)calculateLayoutForCTFrame:(CTFrameRef)ctFrame {
    UIEdgeInsets insets = self.insets;
    CGFloat lineSpace = self.lineSpace;
    
    CFArrayRef ctLines = CTFrameGetLines(ctFrame);
    CFIndex lineCount = CFArrayGetCount(ctLines);
    for (NSUInteger i = 0; i < lineCount; i++) {
        CTLineRef ctLine = CFArrayGetValueAtIndex(ctLines, i);
        CGFloat ascent;
        CGFloat descent;
        CGFloat lineWidth = CTLineGetTypographicBounds(ctLine, &ascent, &descent, NULL);
        //这里descent一直是font.descent的值，取最大的才正确。
        self.maxDescent = MAX(self.maxDescent, descent);
        _maxLineHeight = MAX(_maxLineHeight, ascent + self.maxDescent);
        _maxLineWidth  = MAX(_maxLineWidth, lineWidth);
        _maxAscent     = MAX(_maxAscent, ascent);
    }
    
    [self.attachmentDatas enumerateObjectsUsingBlock:^(QGAttachmentData * _Nonnull attachmentData, NSUInteger idx, BOOL * _Nonnull stop) {
        
        for (NSUInteger i = 0; i < lineCount; i++) {
            CTLineRef ctLine = CFArrayGetValueAtIndex(ctLines, i);
            for (id runObj in (NSArray *)CTLineGetGlyphRuns(ctLine)) {
                CTRunRef run = (__bridge CTRunRef)runObj;
                CFRange runRange = CTRunGetStringRange(run);
                if (runRange.location <= attachmentData.location && runRange.location+runRange.length > attachmentData.location) {
                    CGRect runRect;
                    CGFloat ascent;//height above the baseline
                    CGFloat descent;//height below the baseline
                    runRect.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
                    runRect.size.height = ascent-descent;
                    runRect.origin.x = CTLineGetOffsetForStringIndex(ctLine, runRange.location, NULL);
                    runRect.origin.y = self.constraintSize.height - insets.top - self.maxLineHeight + (self.maxLineHeight-runRect.size.height)/2 - i*(self.maxLineHeight+lineSpace);
                    attachmentData.drawRect = runRect;
                    attachmentData.imageFrame = CGRectMake(runRect.origin.x, insets.top + (self.maxLineHeight-runRect.size.height)/2 + i*(self.maxLineHeight+lineSpace), runRect.size.width, runRect.size.height);
                }
            }
        }
    }];
    
    _bounds = CGRectMake(0, 0, _maxLineWidth + insets.left + insets.right, (_maxLineHeight+lineSpace)*lineCount-lineSpace + insets.top + insets.bottom);
}

@end
