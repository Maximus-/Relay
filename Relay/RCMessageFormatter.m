//
//  RCMessage.m
//  Relay
//
//  Created by Max Shavrick on 2/20/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "RCMessageFormatter.h"
#import "NSString+IRCStringSupport.h"
@implementation RCMessageFormatter
@synthesize string, highlight, shouldColor;
- (id)initWithMessage:(NSString *)_message isOld:(BOOL)old isMine:(BOOL)m isHighlight:(BOOL)hh type:(RCMessageType)_flavor {
    if ((self = [super init])) {
        shouldColor = NO;
        if (![_message hasSuffix:@"\n"])
            _message = [_message stringByAppendingString:@"\n"];
        switch (_flavor) {
            case RCMessageTypeAction:
                self.string = [@"ACTION-" stringByAppendingString:_message];
                shouldColor = YES;
                goto isMnt;
                break;
            case RCMessageTypeNormal:
                self.string = [@"NORMAL-" stringByAppendingString:_message];
                shouldColor = YES;
                goto isMnt;
                break;
            case RCMessageTypeNotice:
                self.string = [@"NOTICE-" stringByAppendingString:_message];
                shouldColor = YES;
                goto isMnt;
                break;
            case RCMessageTypeTopic:
                self.string = [@"TOPIC-" stringByAppendingString:_message];
                break;
            case RCMessageTypeJoin:
                self.string = [@"JOIN-" stringByAppendingString:_message];
                break;
            case RCMessageTypePart:
                self.string = [@"PART-" stringByAppendingString:_message];
                break;
            case RCMessageTypeQuit:
                self.string = [@"QUIT-" stringByAppendingString:_message];
                break;
            case RCMessageTypeBan:
                self.string = [@"BAN-" stringByAppendingString:_message];
                break;
            case RCMessageTypeKick:
                self.string = [@"KICK-" stringByAppendingString:_message];
                break;
            case RCMessageTypeMode:
                self.string = [@"MODE-" stringByAppendingString:_message];
                break;
            case RCMessageTypeError:
                self.string = [@"ERROR-" stringByAppendingString:_message];
                break;
            case RCMessageTypeNormalE:
                self.string = [@"EXCEPTION-" stringByAppendingString:_message];
                break;
            case RCMessageTypeEvent:
                self.string = [@"EVENT-" stringByAppendingString:_message];
                break;
            default:
                break;
        }
        self.shouldColor = NO;
        self.highlight = NO;
        goto out_;
    isMnt:
        [self setString:[@":" stringByAppendingString:[self string]]];
        if (m) {
            [self setString:[@"M" stringByAppendingString:[self string]]];
        } else if (hh) {
            self.highlight = YES;
            [self setString:[@"H" stringByAppendingString:[self string]]];
        }
        goto out_;
    }
out_:
    return self;

}

- (void)dealloc {
    [self setString:nil];
	[super dealloc];
}
@end
