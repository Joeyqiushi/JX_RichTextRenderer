# JX_RichTextRenderer

![](https://img.shields.io/github/license/mashape/apistatus.svg) ![](https://img.shields.io/badge/platform-iOS-lightgrey.svg) ![](https://img.shields.io/badge/iOS-8.0%2B-blue.svg)

Rich text renderer implemented by CoreText.

## Usage

 1. Add the source files `JX_RichTextRenderer.h` and `JX_RichTextRenderer.m` to your Xcode project.
 2. Import `JX_RichTextRenderer.h` .
 3. Create a `JX_RichTextRenderer` instance:
 ```
 JX_RichTextRenderer *richTextRenderer = [[JX_RichTextRenderer alloc] initWithAttributedText:attributedString
                                                                                 constraintSize:CGSizeMake(200, CGFLOAT_MAX)
                                                                                         insets:UIEdgeInsetsZero
                                                                                      lineSpace:0];
 ```
 4. Get content size:
 ```
 CGSize contentSize = richTextRenderer.contentSize;
 ```
 5. Get content image:
 ```
 UIImage *richTextImage = [richTextRenderer render];
 ```
 6. Use the image as you want.
 
 You can add or remove functions as you need.
 
 ## Requirements

This component requires `iOS 8.0+`.

## License

JX_GCDTimerManager is provided under the MIT license. See LICENSE file for details.
