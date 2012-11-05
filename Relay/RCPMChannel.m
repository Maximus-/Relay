//
//  RCPMChannel.m
//  Relay
//
//  Created by Max Shavrick on 3/24/12.
//

#import "RCPMChannel.h"
#import "RCNetworkManager.h"
#import "NSString+IRCStringSupport.h"

@implementation RCPMChannel

- (id)initWithChannelName:(NSString *)_name {
	if ((self = [super initWithChannelName:_name])) {
	}
	return self;
}

- (void)changeNick:(NSString*)old toNick:(NSString*)new_ {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        @synchronized(self) {
            if ([old isEqualToString:[self channelName]]) {
                if ([[self delegate] channelWithChannelName: new_]) {
                    id nself = [[self delegate] channelWithChannelName: new_];
                    [self recievedMessage:[NSString stringWithFormat:@"%c\u2022 %@%c is now known as %c%@%c", RCIRCAttributeBold, old, RCIRCAttributeBold, RCIRCAttributeBold, new_, RCIRCAttributeBold] from:@"" type:RCMessageTypeNormalE];
                    [nself recievedMessage:[NSString stringWithFormat:@"%c\u2022 %@%c is now known as %c%@%c", RCIRCAttributeBold, old, RCIRCAttributeBold, RCIRCAttributeBold, new_, RCIRCAttributeBold] from:@"" type:RCMessageTypeNormalE];
                    return;
                }
                [self setChannelName:new_];
            }
            [self recievedMessage:[NSString stringWithFormat:@"%c\u2022 %@%c is now known as %c%@%c", RCIRCAttributeBold, old, RCIRCAttributeBold, RCIRCAttributeBold, new_, RCIRCAttributeBold] from:@"" type:RCMessageTypeNormalE];
        }
    });
}

- (void)shouldPost:(BOOL)isHighlight withMessage:(NSString *)msg {
	[self setUserJoined:[self channelName]];
	[self setUserJoined:[delegate useNick]];
	if ([[RCNetworkManager sharedNetworkManager] isBG]) {
		UILocalNotification *nc = [[UILocalNotification alloc] init];
		[nc setFireDate:[NSDate date]];
		[nc setAlertBody:[msg stringByStrippingIRCMetadata]];
		[nc setSoundName:UILocalNotificationDefaultSoundName];
		[[UIApplication sharedApplication] scheduleLocalNotification:nc];
		[nc release];
	}
}

- (void)setJoined:(BOOL)joind withArgument:(NSString *)arg1 {
    return;
}

- (void)setSuccessfullyJoined:(BOOL)success {
    return;
}

- (void)setJoined:(BOOL)joind {
    return;
}

- (BOOL)joined {
    return YES;
}

- (BOOL)isUserInChannel:(NSString *)user {
    return [user isEqualToString:channelName]||[user isEqualToString:[[self delegate] useNick]];
}

- (BOOL)isPrivate {
    return YES;
}

@end
