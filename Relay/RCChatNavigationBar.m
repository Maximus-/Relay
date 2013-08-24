//
//  RCChatNavigationBar.m
//  Relay
//
//  Created by Max Shavrick on 10/27/12.
//

#import "RCChatNavigationBar.h"
#import "RCChatController.h"

@implementation RCChatNavigationBar
@synthesize subtitle, title, isMain, superSpecialLikeAc3xx2, maxSize;

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		title = nil;
		subtitle = nil;
		maxSize = 18;
		[self setOpaque:NO];
		 /*
		CALayer *hshdw = [[CALayer alloc] init];
		UIImage *hfs = [UIImage imageNamed:@"0_vzshdw"];
		[hshdw setContents:(id)hfs.CGImage];
		[hshdw setShouldRasterize:YES];
		[hshdw setFrame:CGRectMake(0, 44, 320, hfs.size.height)];
		[hshdw setOpacity:0.7];
		[self.layer setMasksToBounds:NO];
		[self.layer addSublayer:hshdw];
		[hshdw release];
		 */
		UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, frame.size.width, 48) byRoundingCorners:UIRectCornerTopLeft| UIRectCornerTopRight cornerRadii:CGSizeMake(3, 3)];
		CAShapeLayer *maskLayer = [CAShapeLayer layer];
		maskLayer.frame = CGRectMake(0, 0, 320, 48);
		maskLayer.path = maskPath.CGPath;
		self.layer.mask = maskLayer;
		UITapGestureRecognizer *gs = [[UITapGestureRecognizer alloc] initWithTarget:[RCChatController sharedController] action:@selector(showMenuOptions:)];
		[self addGestureRecognizer:gs];
		[gs release];
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	int loc = 0;
	for (UIButton *btn in self.subviews) {
		if (loc == 0) {
			// do nothing..
		}
		if (loc == 1) {
			[btn setFrame:CGRectMake(self.frame.size.width - btn.frame.size.width - 4 + (superSpecialLikeAc3xx2 ? (-52) : 0), btn.frame.origin.y, btn.frame.size.width, btn.frame.size.height)];
		}
		loc++;
	}
}

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	self.layer.mask.frame = CGRectMake(0, 0, frame.size.width, frame.size.height+4);
	UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.layer.mask.frame byRoundingCorners:UIRectCornerTopLeft| UIRectCornerTopRight cornerRadii:CGSizeMake(3, 3)];
	CAShapeLayer *shp = (CAShapeLayer *)self.layer.mask;
	shp.path = maskPath.CGPath;
}

- (void)setIsMain:(BOOL)_isMain {
	if (isMain) return;
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
	[btn setFrame:CGRectMake(55, 2, 218, 40)];
	[btn setBackgroundColor:[UIColor clearColor]];
	[btn addTarget:[RCChatController sharedController] action:@selector(showMenuOptions:) forControlEvents:UIControlEventTouchUpInside];
	[btn setTag:1132];
	[self addSubview:btn];
	isMain = _isMain;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	[[UIColor clearColor] set];
	[[UIColor clearColor] setFill];
	UIImage *bg;
	if (isiOS7)
		bg = [[RCSchemeManager sharedInstance] imageNamed:@"ios7_mainnavbarbg"];
	else bg = [[RCSchemeManager sharedInstance] imageNamed:@"mainnavbarbg"];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[bg drawInRect:rect];
	if ([[self subviews] count] > 2) return; // kind of fixes it. eh
	
	UIColor *shadowColor = nil;
	UIColor *fillColor = nil;
	CGSize shadowOffset = CGSizeZero;
	if ([[RCSchemeManager sharedInstance] isDark]) {
		shadowColor = [UIColor blackColor];
		fillColor = [UIColor whiteColor];
		shadowOffset = CGSizeMake(0, -1);
	}
	else {
		shadowColor = [UIColor whiteColor];
		fillColor = UIColorFromRGB(0x4c4c51);
		shadowOffset = CGSizeMake(0, .5);
	}
	
	CGContextSetShadowWithColor(ctx, shadowOffset, 1, shadowColor.CGColor);
	CGContextSetFillColorWithColor(ctx, fillColor.CGColor);
	CGFloat size = 0.0;
	float maxWidth = (rect.size.width - 90);
	[title sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:maxSize] minFontSize:12 actualFontSize:&size forWidth:maxWidth lineBreakMode:NSLineBreakByClipping];
	[title drawInRect:CGRectMake((!superSpecialLikeAc3xx2 ? 45 : 22), ((!superSpecialLikeAc3xx2 && isiOS7) ? 7 : 0) + (isiOS7 ? 10 : 0) + (!!subtitle ? 1.5 + (size <= 18 ? 2 : 0) : (((rect.size.height-4)/2)-(size/2))), maxWidth, 30) withFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:size] lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
	if (subtitle) {
		CGFloat subsze = 0.0;
		[subtitle sizeWithFont:[UIFont systemFontOfSize:11] minFontSize:10 actualFontSize:&subsze forWidth:maxWidth lineBreakMode:NSLineBreakByClipping];
		[subtitle drawInRect:CGRectMake(50, 24 + (isiOS7 ? 17 : 0), (!superSpecialLikeAc3xx2 ? maxWidth-10 : 175), 14) withFont:[UIFont systemFontOfSize:subsze] lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
	}
}

- (void)dealloc {
	[title release];
	[subtitle release];
	[super dealloc];
}

@end
