//
//  RCRoomScrollView.m
//  Relay
//
//  Created by Max Shavrick on 2/25/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "RCChannelScrollView.h"

@implementation RCChannelScrollView

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self setScrollEnabled:YES];
		[self setDirectionalLockEnabled:NO];
	}
	return self;
}

- (void)layoutChannels:(NSArray *)channels {
	if ([[self gestureRecognizers] count] != 0) {
		for (id recog in [self gestureRecognizers]) {
			if ([recog isKindOfClass:[UITapGestureRecognizer class]]) [self removeGestureRecognizer:recog];
		}
	}
	for (id subview in [self subviews]) [subview removeFromSuperview];
	if ([channels count] == 0) {
		UILabel *nothingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 7.5, 320, 16)];
		nothingLabel.textAlignment = UITextAlignmentCenter;
		nothingLabel.text = @"You have no rooms for this server.. :(";
		nothingLabel.font = [UIFont systemFontOfSize:10];
		nothingLabel.backgroundColor = [UIColor clearColor];
		nothingLabel.textColor = [UIColor darkGrayColor];
		UITapGestureRecognizer *recog = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wantsToJoinChannel:)];
		[recog setNumberOfTapsRequired:2];
		[self addGestureRecognizer:recog];
		[recog release];
		[self addSubview:nothingLabel];
		[nothingLabel release];
		return;
	}
	for (RCChannelBubble *bb in channels) {
		UIView *sub = nil;
		if ([[self subviews] count] != 0) sub = [[self subviews] objectAtIndex:[[self subviews] count]-1];
		[bb setFrame:CGRectMake((sub ? sub.frame.size.width+sub.frame.origin.x+10 : 10), 7, bb.frame.size.width, 20)];
		if ([bb _selected]) {
			[[bb titleLabel] setTextColor:[UIColor whiteColor]];
			[[bb titleLabel] setShadowColor:[UIColor blackColor]];
		}
		else {
			[[bb titleLabel] setTextColor:[UIColor blackColor]];
			[[bb titleLabel] setShadowColor:[UIColor whiteColor]];
		}
		[self addSubview:bb];
	}
	[self fixLayout];
}

- (void)fixLayout {
	if ([[self subviews] count] == 0) return;

	UIView *sub = nil;
	sub = [[self subviews] objectAtIndex:0];
	for (UIView *subv in [self subviews]) {
		if ([subv frame].origin.x > sub.frame.origin.x) sub = subv;
	}
	[self setContentSize:CGSizeMake((sub.frame.origin.x + sub.frame.size.width+10), self.frame.size.height)];
	[self setScrollEnabled:YES];
}

- (void)wantsToJoinChannel:(UIGestureRecognizer *)recog {
	NSLog(@"hai");
}

- (void)drawRect:(CGRect)rect {
	@autoreleasepool {
		UIImage *bg = [UIImage imageNamed:@"0_chanbar"];
		[bg drawInRect:rect];
	}
}
@end
