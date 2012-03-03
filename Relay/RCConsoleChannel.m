//
//  RCConsoleChannel.m
//  Relay
//
//  Created by Max Shavrick on 3/2/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "RCConsoleChannel.h"

@implementation RCConsoleChannel

- (void)recievedMessage:(NSString *)message from:(NSString *)from type:(RCMessageType)type {
	
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	RCMessageFlavor flavor;
	switch (type) {
		case RCMessageTypeAction:
			lastMessage = [[NSString stringWithFormat:@"\u2022 %@ %@", from, message] copy];
			flavor = RCMessageTypeAction;
			break;
		case RCMessageTypeNormal:
			lastMessage = [[NSString stringWithFormat:@" %@", message] copy];
			flavor = RCMessageFlavorNormalE;
			break;
		case RCMessageTypeNotice:
			flavor = RCMessageFlavorNotice;
			break;
	}
	[panel postMessage:lastMessage withFlavor:flavor isHighlight:NO];
	[self updateMainTableIfNeccessary];
	[p drain];
	return;
}

@end
