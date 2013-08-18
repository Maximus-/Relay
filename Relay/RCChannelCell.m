//
//  RCChannelCell.m
//  Relay
//
//  Created by Max Shavrick on 6/22/12.
//

#import "RCChannelCell.h"

@implementation RCChannelCell
@synthesize channel, white, newMessageCount, hasHighlights;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	[UIColorFromRGB(0x3d3d40) set];
	UIRectFill(CGRectMake(0, 0, rect.size.width, rect.size.height));
	UIImage *arrow = [UIImage imageNamed:@"0_arrowr"];
	[arrow drawInRect:CGRectMake(232, 14, 16, 16)];
	[UIColorFromRGB(0x2A2E37) set];
	if (!self.channel) return;
	BOOL isPM = (![self.channel hasPrefix:@"#"] && ![self.channel hasPrefix:@"\x01"]);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetShadowWithColor(ctx, CGSizeMake(0, -1), 0, [UIColor blackColor].CGColor);
	UIColor *def = UIColorFromRGB(0xcfcfcf);
	if (white || fakeWhite) def = UIColorFromRGB(0xfbf8f8);
	CGContextSetFillColorWithColor(ctx, def.CGColor);
	CGContextScaleCTM(ctx, [[UIScreen mainScreen] scale], [[UIScreen mainScreen] scale]);

	[channel drawAtPoint:CGPointMake(20, 3.5) forWidth:(newMessageCount > 0 ? (newMessageCount > 99 ? 90 : 95) : 95) withFont:[UIFont systemFontOfSize:8] minFontSize:5 actualFontSize:NULL lineBreakMode:NSLineBreakByCharWrapping baselineAdjustment:UIBaselineAdjustmentAlignCenters];
	UIImage *glyph = nil;
	if (isPM) {
		glyph = [UIImage imageNamed:@"usericon"];
	}
	else {
		glyph = [UIImage imageNamed:@"channelbubble"];
	}
	[glyph drawInRect:CGRectMake(4, 4, 12, 12) blendMode:kCGBlendModeNormal alpha:0.5];
	if (newMessageCount > 0) {
		NSString *rendr = @"";
		if (newMessageCount > 99) {
			rendr = @"99+";
		}
		else {
			rendr = [NSString stringWithFormat:@"%d", newMessageCount];
		}
	//	UIImage *bubble = [UIImage imageNamed:@"highlightbadge"];
	//	[bubble drawInRect:CGRectMake(100, 2, 10, 12)];
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	fakeWhite = YES;
	[self setNeedsDisplay];
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	fakeWhite = NO;
	[self setNeedsDisplay];
	[super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	fakeWhite = NO;
	[self setNeedsDisplay];
	[super touchesEnded:touches withEvent:event];
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];
}

- (id)description {
	return [NSString stringWithFormat:@"<%@: %p; frame = %@; channel = %@", NSStringFromClass([self class]), self, NSStringFromCGRect(self.frame), self.channel];
}

@end