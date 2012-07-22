//
//  RCWelcomeNetwork.m
//  Relay
//
//  Created by Max Shavrick on 2/27/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "RCWelcomeNetwork.h"

@implementation RCWelcomeNetwork

- (void)addChannel:(NSString *)_chan join:(BOOL)join {
	RCWelcomeChannel *chan = [[RCWelcomeChannel alloc] initWithChannelName:_chan];
	[chan setDelegate:self];
	[chan setSuccessfullyJoined:YES];
	[[self _channels] setObject:chan forKey:_chan];
	[chan release];
	[chan setJoined:YES withArgument:nil];
}

- (void)connect {
}

- (BOOL)sendMessage:(NSString *)msg {
	return YES;
}

@end
