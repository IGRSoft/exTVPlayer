//
//  UIView+Extension.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 1/14/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "UIView+Extension.h"

@implementation UIView (Extension)

@dynamic borderColor, borderWidth, cornerRadius;

- (void)setBorderColor:(UIColor *)borderColor
{
	(self.layer).borderColor = borderColor.CGColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
	(self.layer).borderWidth = borderWidth;
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
	(self.layer).cornerRadius = cornerRadius;
}

@end
