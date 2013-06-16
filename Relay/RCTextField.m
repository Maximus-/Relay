//
//  RCTextField.m
//  Relay
//
//  Created by Max Shavrick on 3/21/12.
//

#import "RCTextField.h"

#if USE_PRIVATE
@interface RCTextField (RCPrivate_)
- (void)setInsertionPointColor:(UIColor *)color;
@end
#endif

@implementation RCTextField

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self setTextColor:UIColorFromRGB(0x56595A)];
		[self setFont:[UIFont systemFontOfSize:12]];
		[self setClearButtonMode:UITextFieldViewModeWhileEditing];
#if USE_PRIVATE
		if ([self respondsToSelector:@selector(setInsertionPointColor:)])
			[self setInsertionPointColor:UIColorFromRGB(0x4F94EA)];
#endif
	}
	return self;
}
/*
- (void)drawPlaceholderInRect:(CGRect)rect {
	[UIColorFromRGB(0xCDCDCD) setFill];
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetShadowWithColor(context, CGSizeMake(0, 1), 0, [UIColor whiteColor].CGColor);
	[self.placeholder drawAtPoint:CGPointMake(rect.origin.x, 0) withFont:[UIFont systemFontOfSize:13]];
}*/

@end
