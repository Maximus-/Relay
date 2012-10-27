//
//  RCNetworkHeaderButton.m
//  Relay
//
//  Created by Max Shavrick on 10/21/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "RCNetworkHeaderButton.h"
#import "RCnetwork.h"

@implementation RCNetworkHeaderButton
@synthesize section;

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		_pSelected = NO;
	}
	return self;
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];
	[self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	_pSelected = YES;
	[self setNeedsDisplay];
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	_pSelected = NO;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	
	if ([net _selected]) {
		UIImage *img = [UIImage imageNamed:@"0_cell_selec"];
		[img drawAsPatternInRect:CGRectMake(6, 0, 242, 42)];
	}
	UIImage *ul = [UIImage imageNamed:@"0_underline"];
	[ul drawAsPatternInRect:CGRectMake(6, 42, 242, 2)];
	NSString *text = [net _description];
	NSString *detail = [net server];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1), 0, [UIColor blackColor].CGColor);
	CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
	CGContextScaleCTM(ctx, [[UIScreen mainScreen] scale], [[UIScreen mainScreen] scale]);
	[text drawInRect:CGRectMake(10, 1, 200, 40) withFont:[UIFont boldSystemFontOfSize:9] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentLeft];
	CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.8 alpha:0.8].CGColor);
	[detail drawInRect:CGRectMake(10, 12, 200, 30) withFont:[UIFont boldSystemFontOfSize:5.5]];
}

- (void)setNetwork:(RCNetwork *)_net {
	net = [_net retain];
	_pSelected = [net _selected];
}

- (RCNetwork *)net {
	return net; // please excuse me for this mess.
}

- (void)dealloc {
	[net release];
	[super dealloc];
}

@end