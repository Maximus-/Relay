//
//  RCChatCell.m
//  Relay
//
//  Created by Max Shavrick on 2/17/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "RCChatCell.h"


@implementation RCChatCell
@synthesize textLabel, message;

CTFontRef CTFontCreateFromUIFont(UIFont *font) {
	CTFontRef ctFont = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, NULL);
	return ctFont;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.textLabel = [[OHAttributedLabel alloc] init];
		[self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		self.textLabel.font = [UIFont boldSystemFontOfSize:12];
		self.textLabel.extendBottomToFit = YES;
		self.textLabel.backgroundColor = [UIColor clearColor];
		self.backgroundColor = [UIColor whiteColor];
		[self setSelectionStyle:UITableViewCellSelectionStyleNone];
		[self.textLabel setAutomaticallyAddLinksForType:NSTextCheckingAllTypes];
		[self.textLabel setLinkColor:UIColorFromRGB(0x4F94EA)];
		[self.textLabel setUnderlineLinks:NO];
		[self.textLabel setShadowColor:[UIColor whiteColor]];
		[self.textLabel setShadowOffset:CGSizeMake(0, 1)];
		[self addSubview:self.textLabel];
		[self.textLabel release];
	}
	return self;
}

- (void)_textHasBeenSet {
	self.textLabel.text = [message message];
	RCMessageFlavor flavor = [message flavor];
	NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:self.textLabel.text];
	[attr setTextColor:[UIColor blackColor]];
	[attr setFont:[UIFont fontWithName:@"Helvetica" size:12]];
	[attr setTextColor:UIColorFromRGB(0x3F4040)];
	self.backgroundColor = [UIColor whiteColor];
	@autoreleasepool {
		UIImage *bg = [UIImage imageNamed:@"0_chatcell"];
		[self.contentView setBackgroundColor:[UIColor colorWithPatternImage:bg]];
		[self setNeedsDisplay];
	}
	switch (flavor) {
		case RCMessageFlavorAction:
			[attr setTextIsUnderlined:NO range:NSMakeRange(0, self.textLabel.text.length)];
			[attr setTextBold:YES range:NSMakeRange(0, self.textLabel.text.length)];
			[attr setTextAlignment:CTTextAlignmentFromUITextAlignment(UITextAlignmentCenter) lineBreakMode:CTLineBreakModeFromUILineBreakMode(UILineBreakModeClip)];
			break;
		case RCMessageFlavorNormal:
			if ([message highlight]) {
				NSLog(@"Hai. %@", [message highlight]);
				[attr setTextColor:UIColorFromRGB(0x4F94EA) range:[[self.textLabel.text lowercaseString] rangeOfString:[[message highlight] lowercaseString]]];
			}
			[attr setTextBold:YES range:NSMakeRange(0, [self.textLabel.text rangeOfString:@":"].location)];
			break;
		case RCMessageFlavorNotice:
			[attr setTextBold:YES range:NSMakeRange(0, self.textLabel.text.length)];
			self.backgroundColor = [UIColor redColor];
			break;
		case RCMessageFlavorTopic:
			[attr setTextAlignment:CTTextAlignmentFromUITextAlignment(UITextAlignmentCenter) lineBreakMode:CTLineBreakModeFromUILineBreakMode(UILineBreakModeWordWrap)];
			break;
		case RCMessageFlavorJoin:
			[attr setFont:[UIFont fontWithName:@"Helvetica" size:11]];
			[attr setTextAlignment:CTTextAlignmentFromUITextAlignment(UITextAlignmentCenter) lineBreakMode:CTLineBreakModeFromUILineBreakMode(UILineBreakModeWordWrap)];
			[self.contentView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"0_joinbar"]]];
			break;
		case RCMessageFlavorPart:
			[attr setFont:[UIFont fontWithName:@"Helvetica" size:11]];
			[attr setTextAlignment:CTTextAlignmentFromUITextAlignment(UITextAlignmentCenter) lineBreakMode:CTLineBreakModeFromUILineBreakMode(UILineBreakModeWordWrap)];
			[self.contentView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"0_joinbar"]]];
			break;
		case RCMessageFlavorNormalE:
		//	[attr setTextBold:YES range:NSMakeRange(0, self.textLabel.text.length)];
			break;
	}
	if ([message isMine]) {
		[attr setTextColor:UIColorFromRGB(0xA1B1BC)];
	}
	[self.textLabel setAttributedText:attr];
	[attr release];
	height = [self calculateHeightForLabel];
	if (height > 15) {
		@autoreleasepool {
			UIImage *bg = [UIImage imageNamed:@"0_chatcell_2"];
			[self.contentView setBackgroundColor:[UIColor colorWithPatternImage:bg]];
			[self setNeedsDisplay];
		}
	}
}

- (float)calculateHeightForLabel {
	
	int maxWidth = [[UIScreen mainScreen] applicationFrame].size.width-4; // 2 here, 2 there.. :P
	int lengthOfName, lengthOfMsg, finalLength, heightToUse;
	if (currentFlavor == RCMessageFlavorNormal) {
		lengthOfName = [[self.textLabel.text substringWithRange:NSMakeRange(0, [self.textLabel.text rangeOfString:@":"].location)] sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]].width;
		lengthOfMsg = [[self.textLabel.text substringWithRange:NSMakeRange([self.textLabel.text rangeOfString:@":"].location, self.textLabel.text.length-[self.textLabel.text rangeOfString:@":"].location)] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:12]].width;
		finalLength = lengthOfMsg += lengthOfName;
		heightToUse = (((finalLength += maxWidth) - (finalLength % maxWidth))/maxWidth);
	}
	else {
		lengthOfMsg = [self.textLabel.text sizeWithFont:[UIFont fontWithName:@"Helvetica" size:12]].width;
		if (maxWidth >= lengthOfMsg) return 15;
		else heightToUse = (((lengthOfMsg += maxWidth) - (lengthOfMsg % maxWidth))/maxWidth);
	}
	return (heightToUse <= 1 ? 1 : heightToUse) * 15;;
	
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self.textLabel setFrame:CGRectMake(2, 2, 316, height)];
	[self.textLabel setNeedsDisplay];
}

@end
