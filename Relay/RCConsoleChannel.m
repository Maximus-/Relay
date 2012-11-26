//
//  RCConsoleChannel.m
//  Relay
//
//  Created by Max Shavrick on 3/2/12.
//

#import "RCConsoleChannel.h"
#import "RCChatView.h"
#import "RCNetwork.h"

@implementation RCConsoleChannel

- (id)initWithChannelName:(NSString *)_name {
    if ((self = [super initWithChannelName:_name])) {
        joined = YES;
    }
    return self;
}

- (BOOL)joined {
    return YES;
}

- (void)setSuccessfullyJoined:(BOOL)success {
    joined = YES;
}

- (void)userWouldLikeToPartakeInThisConversation:(NSString *)message {
	@autoreleasepool {
		if ([message hasPrefix:@"/"]) {
			[self parseAndHandleSlashCommand:[message substringFromIndex:1]];
			return;
		}
		else {
			[(RCNetwork *)delegate sendMessage:message];
			[self recievedMessage:message from:@"" type:RCMessageTypeNormalE];
		}
	}
}

- (void)recievedMessage:(NSString *)message from:(NSString *)from type:(RCMessageType)type {
	NSString *msg = @"";
    NSString *time = @"";
	time = [[RCDateManager sharedInstance] currentDateAsString];
	if ([time hasSuffix:@" "])
		time = [time substringToIndex:time.length-1];
			//msg = [[NSString stringWithFormat:@"%c[%@]%c %@ sets mode +b %@",RCIRCAttributeBold, time, RCIRCAttributeBold, from, message] retain];
	if (type == RCMessageTypeAction) {
		msg = [[NSString stringWithFormat:@"%c[%@] \u2022 %@%c %@", RCIRCAttributeBold, time, from, RCIRCAttributeBold, message] retain];
	}
	else if (type == RCMessageTypeNormal) {
		if (from) {
			msg = [[NSString stringWithFormat:@"%c[%@]%@%c: %@", RCIRCAttributeBold, time, from, RCIRCAttributeBold, message] retain];
		}
		else {
			msg = [[NSString stringWithFormat:@"%c[%@]%c %@", RCIRCAttributeBold, time, RCIRCAttributeBold, message] retain];
		}
		type = RCMessageTypeNormalE;
	}
	else if (type == RCMessageTypeNotice) {
        msg = [[NSString stringWithFormat:@"%c[%@] -%@-%c %@", RCIRCAttributeBold, time, from, RCIRCAttributeBold, message] retain];
	}
	else if (type == RCMessageTypeJoin) {
		msg = [@"iPhone joined the channel." retain];
	}
	else {
		[super recievedMessage:message from:from type:type];
		return;
	}
	[panel postMessage:[msg autorelease] withType:type highlight:NO];
}

@end