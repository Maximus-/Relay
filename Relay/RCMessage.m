//
//  RCMessage.m
//  Relay
//
//  Created by Max Shavrick on 2/20/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "RCMessage.h"

@implementation RCMessage
@synthesize flavor, message, highlight, isMine, isOld;

- (void) encodeWithCoder: (NSCoder *)coder {
	[coder encodeObject:message forKey:@"0_MSGKEY"];
	[coder encodeObject:[NSNumber numberWithBool:isMine] forKey:@"0_ISMINE"];
	[coder encodeObject:[NSNumber numberWithInt:flavor] forKey:@"0_FLVRKEY"];
	[coder encodeObject:[NSNumber numberWithBool:highlight] forKey:@"0_HGHLGHTKEY"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        NSAutoreleasePool *poolz = [[NSAutoreleasePool alloc] init];
		[self setMessage:[coder decodeObjectForKey:@"0_MSGKEY"]];
		[self setFlavor:(RCMessageFlavor)[[coder decodeObjectForKey:@"0_FLVRKEY"] intValue]];
		[self setHighlight:[[coder decodeObjectForKey:@"0_HGHLGHTKEY"] boolValue]];
		[self setIsMine:[[coder decodeObjectForKey:@"0_ISMINE"] boolValue]];
		self.isOld = YES;
        [poolz drain];
    }
    return self;
}

- (id)init {
	if ((self = [super init])) {
		isOld = NO;
	}
	return self;
}

- (void)dealloc {
	[message release];
	[super dealloc];
}
@end
