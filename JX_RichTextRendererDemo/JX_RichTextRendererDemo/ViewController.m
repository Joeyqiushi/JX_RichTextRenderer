//
//  ViewController.m
//  JX_RichTextRendererDemo
//
//  Created by Joey Xu on 2018/11/17.
//  Copyright © 2018 Joey Xu. All rights reserved.
//

#import "ViewController.h"
#import "JX_RichTextRenderer.h"

@interface ViewController ()
@property (nonatomic, strong) JX_RichTextRenderer *richTextRenderer;
@property (nonatomic, strong) UIView *richTextView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString new];
    
    NSMutableAttributedString *textAttri = [[NSMutableAttributedString alloc] initWithString:@"This is a rich text string."
                                                                                         attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:22.0]}];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithData:nil ofType:nil];
    attachment.bounds = CGRectMake(0, 0, 33, 33);
    attachment.image = [UIImage imageNamed:@"smile"];
    NSAttributedString *attachmentAttri = [NSAttributedString attributedStringWithAttachment:attachment];
    
    [attributedString appendAttributedString:textAttri];
    [attributedString appendAttributedString:attachmentAttri];
    
    JX_RichTextRenderer *richTextRenderer = [[JX_RichTextRenderer alloc] initWithAttributedText:attributedString
                                                                                 constraintSize:CGSizeMake(300, CGFLOAT_MAX)
                                                                                         insets:UIEdgeInsetsZero
                                                                                      lineSpace:0];
    CGSize contentSize = richTextRenderer.contentSize;
    UIImage *richTextImage = [richTextRenderer render];
    
    self.richTextRenderer = richTextRenderer;
    
    // all the above tasks are legal to be executed in subthread.
    
    UIView *view = [UIView new];
    view.frame = CGRectMake(100, 300, contentSize.width, contentSize.height);
    view.layer.contentsGravity = kCAGravityBottomLeft;
    view.layer.contentsScale = [UIScreen mainScreen].scale;
    view.layer.contents = (__bridge id _Nullable)(richTextImage.CGImage);
    [self.view addSubview:view];
    self.richTextView = view;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
    [view addGestureRecognizer:tap];
}

- (void)tapGestureRecognized:(UITapGestureRecognizer *)tapGesture {
    CGPoint location = [tapGesture locationInView:self.richTextView];
    NSInteger characterIndex = [self.richTextRenderer characterIndexForPoint:location];
    if (NSNotFound == characterIndex || characterIndex < 0 || characterIndex > self.richTextRenderer.attributedText.length - 1) {
        return;
    }
    NSAttributedString *character = [self.richTextRenderer.attributedText attributedSubstringFromRange:NSMakeRange(characterIndex, 1)];
    NSRange range = NSMakeRange(0, character.length);
    NSString *message = @"";
    if ([character attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:&range]) {
        message = @"检查到点击图片";
    } else {
        message = [NSString stringWithFormat:@"检查到点击文本-%@", character.string];
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"点击事件响应"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
