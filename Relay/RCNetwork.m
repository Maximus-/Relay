//
//  RCNetwork.m
//  Relay
//
//  Created by Max Shavrick on 1/13/12.
//

#import "RCNetwork.h"
#import "RCNetworkManager.h"
#import "TestFlight.h"
#define RECV_BUF_LEN 10240
@implementation RCNetwork

@synthesize sDescription, server, nick, username, realname, spass, npass, port, isRegistered, useSSL, COL, _channels, useNick, userModes, _bubbles, _nicknames, shouldRequestSPass, shouldRequestNPass, namesCallback;

- (id)init {
	if ((self = [super init])) {
		status = RCSocketStatusClosed;
		shouldSave = NO;
		isRegistered = NO;
		canSend = YES;
		_bubbles = [[NSMutableArray alloc] init];
		_channels = [[NSMutableDictionary alloc] init];
		_isDiconnecting = NO;
        _nicknames = [[NSMutableArray alloc] init];
        if ([self useNick])
            [_nicknames addObject:[self useNick]];
	}
	return self;
}

- (id)infoDictionary {
	NSMutableArray *chanArray = [[NSMutableArray alloc] init];
	for (NSString *_chan in [_channels allKeys]) {
		RCChannel *chan = [self channelWithChannelName:_chan];
		NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
							  _chan, CHANNAMEKEY,
							  ([chan joinOnConnect] ? (id)kCFBooleanTrue : (id)kCFBooleanFalse), @"0_CHANJOC",
							  ([[chan password] length] > 0 ? (id)kCFBooleanTrue : (id)kCFBooleanFalse), @"0_CHANPASS", nil];
		[chanArray addObject:dict];
		[dict release];
	}
	[chanArray autorelease];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			username, USER_KEY,
			nick, NICK_KEY,
			realname, NAME_KEY,
			([spass length] > 0 ? (id)kCFBooleanTrue : (id)kCFBooleanFalse), S_PASS_KEY,
			([npass length] > 0 ? (id)kCFBooleanTrue : (id)kCFBooleanFalse), N_PASS_KEY,
			sDescription, DESCRIPTION_KEY,
			server, SERVR_ADDR_KEY,
			[NSNumber numberWithInt:port], PORT_KEY,
			[NSNumber numberWithBool:useSSL], SSL_KEY,
			chanArray, CHANNELS_KEY,
			[NSNumber numberWithBool:COL], COL_KEY,
			nil];
}

- (void)dealloc {
	NSLog(@"cya.");
	[_channels release];
	[server release];
	[nick release];
	[username release];
	[realname release];
	[spass release];
	[npass release];
	[sDescription release];
    [_nicknames release];
	[super dealloc];
}

- (NSString *)_description {
	if (!sDescription) {
		return server;
	}
	return sDescription;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; %@;>", NSStringFromClass([self class]), self, [self infoDictionary]];
}

- (void)_setupRooms:(NSArray *)rooms {
	[rooms retain];
	for (NSDictionary *dict in rooms) {
		NSString *chan = [dict objectForKey:CHANNAMEKEY];
		if (!chan) continue;
		BOOL jOC = ([dict objectForKey:@"0_CHANJOC"] ? [[dict objectForKey:@"0_CHANJOC"] boolValue] : YES);
		[self addChannel:chan join:NO];
		RCChannel *_chan = [self channelWithChannelName:chan];
		[_chan setJoinOnConnect:jOC];
		RCKeychainItem *item = [[RCKeychainItem alloc] initWithIdentifier:[NSString stringWithFormat:@"%@%@rpass", [self _description], chan] accessGroup:nil];
		[_chan setPassword:[item objectForKey:(id)kSecValueData]];
		[item release];		
	}
	[rooms release];
}

- (void)setupRooms:(NSArray *)rooms {
	[rooms retain];
	for (NSString *_chan in rooms) {
		[self addChannel:_chan join:NO];
	}
	[rooms release];
}

- (RCChannel *)channelWithChannelName:(NSString *)chan {
	return [self channelWithChannelName:chan ifNilCreate:NO];
}

- (RCChannel *)channelWithChannelName:(NSString *)chan ifNilCreate:(BOOL)cr {
    @synchronized(self)
    {
        for (NSString *chan_ in [_channels allKeys]) {
            if ([[chan_ lowercaseString] isEqualToString:[chan lowercaseString]]/* || (![chan hasPrefix:@"#"] && [[[@"#" stringByAppendingString: chan] lowercaseString] isEqualToString:[chan_ lowercaseString]]) */) return [_channels objectForKey:chan_];
        }
        if (cr) {
            [self addChannel:chan join:NO];
        }
        return nil;
    }
}

- (RCChannel* )addChannel:(NSString *)_chan join:(BOOL)join {
    @synchronized(self)
    {
        if ([_chan hasPrefix:@" "]) {
            _chan = [_chan stringByReplacingOccurrencesOfString:@" " withString:@""];
        }
        for (NSString *aChan in [_channels allKeys])
            if ([[aChan lowercaseString] isEqualToString:[_chan lowercaseString]]) return [_channels objectForKey:aChan];
        if (![self channelWithChannelName:_chan ifNilCreate:NO]) {
            RCChannel *chan = nil;
            if ([_chan isEqualToString:@"IRC"]) chan = [[RCConsoleChannel alloc] initWithChannelName:_chan];
            else if ([_chan hasPrefix:@"#"]) chan = [[RCChannel alloc] initWithChannelName:_chan];
            else chan = [[RCPMChannel alloc] initWithChannelName:_chan];
            [chan setDelegate:self];
            [[self _channels] setObject:chan forKey:_chan];
            [chan release];
            if (join) [chan setJoined:YES withArgument:nil];
            if (isRegistered) {
                [[RCNavigator sharedNavigator] addChannel:_chan toServer:self];
                [[RCNetworkManager sharedNetworkManager] saveNetworks];
                shouldSave = YES; // if we aren't registered.. it's _likely_ just setup.
            }
            return chan;
        }
        else {
            RCChannel *chan = [self channelWithChannelName:_chan];
            [chan setSuccessfullyJoined:YES];
            return chan;
        }
    }
}

- (void)removeChannel:(RCChannel *)chan {
	[self removeChannel:chan withMessage:@"Relay Chat."];
}

- (void)removeChannel:(RCChannel *)chan withMessage:(NSString *)quitter {
	if (!chan) return;
	[chan setJoined:NO withArgument:quitter];
	[[RCNavigator sharedNavigator] removeChannel:chan fromServer:self];
	[_channels removeObjectForKey:[chan channelName]];
	[[RCNetworkManager sharedNetworkManager] saveNetworks];
}

#pragma mark - SOCKET STUFF

- (void)connect {
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:[sDescription stringByAppendingFormat:@"-%@%@%@-%d%d", nick, username, server, port, useSSL]];
	[self performSelectorInBackground:@selector(_connect) withObject:nil];
}

- (void)_connect {
    BOOL oTT = tryingToConnect;
    tryingToConnect = YES;
    NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
    canSend = YES;
    isRegistered = NO;
    if (sendQueue) [sendQueue release];
    sendQueue = nil;
    if (status == RCSocketStatusConnecting) goto errme;
    if (status == RCSocketStatusConnected) goto errme;
    useNick = nick;
    self.userModes = @"~&@%+";
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iPhoneOS_4_0) {
        task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:task];
            task = UIBackgroundTaskInvalid;
        }];
    }
    RCChannel *chan = [_channels objectForKey:@"IRC"];
    if (chan) [chan recievedMessage:[NSString stringWithFormat:@"Connecting to %@ on port %d", server, port] from:@"" type:RCMessageTypeNormal];
    status = RCSocketStatusConnecting;
    sockfd = 0;
    int fd = 0;
    char *lbuf = malloc(RECV_BUF_LEN);
    char *pbuf = lbuf;
    int blen   = RECV_BUF_LEN;
    struct sockaddr_in serv_addr;
    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        NSLog(@"ERRRRRRRR00");
    }
    memset(&serv_addr, '0', sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(port);
    char *ip = RCIPForURL(server);
    NSLog(@"hi %@", CFNetworkCopySystemProxySettings());
    if (ip == NULL) {
        // report error..
        NSLog(@"ERRRRRRRR");
        [self disconnectWithMessage:@"Host not found."];
        goto errme;
    }
    if (inet_pton(AF_INET, ip, &serv_addr.sin_addr) <= 0) {
        [self disconnectWithMessage:@"Invalid address."];
        NSLog(@"Errrrrr");
        goto errme;
    }
    if (connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
        [self disconnectWithMessage:[@"Socket error: " stringByAppendingFormat:@"%s", strerror(errno)]];
        NSLog(@"Errrr");
        goto errme;
    }
    if ([spass length] > 0) {
        [self sendMessage:[@"PASS " stringByAppendingString:spass] canWait:NO];
    }
    [self sendMessage:[@"USER " stringByAppendingFormat:@"%@ %@ %@ :%@", (username ? username : nick), nick, nick, (realname ? realname : nick)] canWait:NO];
    [self sendMessage:[@"NICK " stringByAppendingString:nick] canWait:NO];
    
    /*
     
     Buffered read() implementation.
     Designed to fix non-aligned messages being dropped, and improve performance overall.
     -- This may have some logic flaws. Please investigate on it. Xoxo, qwertyoruiop.
     
     */
    
    int kbytes = 0;
    int pbytes = 0;
    int dbytes = 0;
    int bindex = 0;
    int cached = 0;
    while ((fd = read(sockfd, lbuf+cached, blen-cached)) > 0) {
        while (kbytes != fd+cached && kbytes != blen) {
            if (*(lbuf+kbytes) == '\r'||*(lbuf+kbytes) == '\n') {
                pbytes = kbytes;
                if (pbytes - dbytes) {
                    NSAutoreleasePool *pool = [NSAutoreleasePool new];
                    kbytes ++;
                    NSString* message = [[[[[NSString alloc] initWithBytes:(uint8_t*)lbuf+dbytes length:pbytes-dbytes encoding:NSUTF8StringEncoding] autorelease] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    dbytes = kbytes;
                    [self recievedMessage:message];
                    [pool drain];
                } else goto omg;
            } else {
            omg:
                kbytes ++;
            }
        }
        cached = (kbytes) - dbytes;
        bindex -= dbytes;
        bindex += cached;
        if (bindex > blen) {
            [self disconnectWithMessage:@"Excess Flood"];
            goto out_;
        }
        if (cached > blen && dbytes + cached > blen) {
            [self disconnectWithMessage:@"Excess Flood"];
            goto out_;
        }
        memcpy(lbuf, lbuf+dbytes, cached);
        kbytes = cached;
        dbytes = 0;
        pbytes = 0;
    }
    if ([self isConnected]) {
        [self disconnectWithMessage:@"End of stream"];
    }
out_:
    [p drain];
    free(pbuf);
errme:
    tryingToConnect = oTT;
}

char *RCIPForURL(NSString *URL) {
	char *hostname = (char *)[URL UTF8String];
	//BOOL valid;
	//NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
	//	NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:URL];
	//valid = [alphaNums isSupersetOfSet:inStringSet];
	//	if (!valid) return hostname;
	
	//	NSLog(@"MEH %d %@", (int)valid, URL);
	struct addrinfo hints, *res;
	struct in_addr addr;
	int err;
	memset(&hints, 0, sizeof(hints));
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_family = AF_INET;
	if ((err = getaddrinfo(hostname, NULL, &hints, &res)) != 0) {
		return NULL;
	}
	addr.s_addr = ((struct sockaddr_in *)(res->ai_addr))->sin_addr.s_addr;
	freeaddrinfo(res);
	return inet_ntoa(addr);	
}

- (BOOL)sendMessage:(NSString *)msg {
	return [self sendMessage:msg canWait:YES];
}

- (BOOL)sendMessage:(NSString *)msg canWait:(BOOL)canWait {
	if ((!canWait) || isRegistered) {
		msg = [msg stringByAppendingString:@"\r\n"];
		if (canSend) {
			if (send(sockfd, [msg UTF8String], strlen([msg UTF8String]), 0) < 0) {
				NSLog(@"BLASPHEMYY");
                //		[self errorOccured:[oStream streamError]];
				return NO;
			}
			else {
				// success! :D
				return YES;
			}
		}
	}
	// this whole sendqueue shit needs to be cleaned up majorly.
	NSLog(@"Adding to queue... %@:%d:%d",msg, (int)canWait, (int)isRegistered);
	if (!sendQueue) sendQueue = [[NSMutableString alloc] init];
	[sendQueue appendFormat:@"%@\r\n", msg];
	return NO;
}

- (void)errorOccured:(NSError *)error {
	NSLog(@"Error: %@", [error localizedDescription]);
}

- (void)recievedMessage:(NSString *)msg {
    NSLog(@"%@", msg);
	if ([msg isEqualToString:@""] || msg == nil || [msg isEqualToString:@"\r\n"]) return;
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	msg = [msg stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	msg = [msg stringByReplacingOccurrencesOfString:@"\n" withString:@""];	
	if ([msg hasPrefix:@"PING"]) {
		[self handlePING:msg];
		[p drain];
		return;
	}
	else if ([msg hasPrefix:@"ERROR"]) {
		//handle..
		NSLog(@"Errorz. %@:%@", msg, server);
		NSString *error = [msg substringWithRange:NSMakeRange(5, [msg length]-5)];
		if ([error hasPrefix:@" :"]) error = [error substringFromIndex:2];
		RCChannel *chan = [_channels objectForKey:@"IRC"];
		[chan recievedMessage:error from:@"" type:RCMessageTypeNormal];
		[p drain];
		return;
	}
	if (![msg hasPrefix:@":"]) {
		[p drain];
		return;
	}
	NSScanner *scanner = [[NSScanner alloc] initWithString:msg];
	NSString *crap = @"";
	NSString *cmd = crap;
	NSString *rest = cmd;
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&cmd];
	[scanner scanUpToString:@"\r\n" intoString:&rest];
	NSString *selName = [NSString stringWithFormat:@"handle%@:", cmd];
	SEL pSEL = NSSelectorFromString(selName);
	if ([self respondsToSelector:pSEL]) [self performSelector:pSEL withObject:msg];
	else {
		NSLog(@"PLZ IMPLEMENT %s %@", (char *)pSEL, msg);
		NSLog(@"Meh. %@\r\n%@", cmd, rest);	
	}
	[scanner release];
	[p drain];
}

- (BOOL)isTryingToConnectOrConnected
{
    return ([self isConnected] || tryingToConnect);
}

- (NSString*)defaultQuitMessage
{
    return @"Relay 1.0"; // TODO: return something else if user wants to
}

- (BOOL)disconnectWithMessage:(NSString*)msg
{
    if (_isDiconnecting) return NO;
	_isDiconnecting = YES;
	if (status == RCSocketStatusClosed) return NO;
	if ((status == RCSocketStatusConnected) || (status == RCSocketStatusConnecting)) {
		[self sendMessage:[@"QUIT :" stringByAppendingString:([msg isEqualToString:@"Disconnected."] ? [self defaultQuitMessage] : msg)]];
		status = RCSocketStatusClosed;
		if (sendQueue) [sendQueue release];
		sendQueue = nil;
		close(sockfd);
		[[UIApplication sharedApplication] endBackgroundTask:task];
		task = UIBackgroundTaskInvalid;
		status = RCSocketStatusClosed;
		isRegistered = NO;
		for (NSString *chan in [_channels allKeys]) {
			RCChannel *_chan = [self channelWithChannelName:chan];
			[_chan disconnected:msg];
		}
		NSLog(@"Disconnected.");
	}
	_isDiconnecting = NO;
	return YES;
}

- (BOOL)disconnect {
    return [self disconnectWithMessage:@"Disconnected."];
}

- (void)networkDidRegister:(BOOL)reg {
	// do jOC (join on connect) rooms
	isRegistered = YES;
	RCChannel *chan = [_channels objectForKey:@"IRC"];
	if (chan) [chan recievedMessage:@"Connected to host." from:@"" type:RCMessageTypeNormal];
	if ([npass length] > 0)	[self sendMessage:[@"PRIVMSG NickServ IDENTIFY " stringByAppendingString:npass]];
	for (NSString *chan in [_channels allKeys]) {
		if ([[self channelWithChannelName:chan] joinOnConnect]) [[self channelWithChannelName:chan] setJoined:YES withArgument:nil];
	}
}

- (BOOL)isConnected {
	return (status == RCSocketStatusConnected);
}

- (void)handle001:(NSString *)welcome {
	status = RCSocketStatusConnected;
	[self networkDidRegister:YES];
	NSScanner *scanner = [[NSScanner alloc] initWithString:welcome];
	NSString *crap;
	@try {
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner setScanLocation:[scanner scanLocation]+1];
		[scanner scanUpToString:@"\r\n" intoString:&crap];
	}
	@catch (NSException *exception) {
		NSLog(@"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF %s", (char *)_cmd);
	}
	if ([crap hasPrefix:@":"]) crap = [crap substringFromIndex:1];
	RCChannel *chan = [_channels objectForKey:@"IRC"];
	if (chan) [chan recievedMessage:crap from:@"" type:RCMessageTypeNormal];
	[scanner release];
}


- (void)handle002:(NSString *)infos {
	NSScanner *scanner = [[NSScanner alloc] initWithString:infos];
	NSString *crap;
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner setScanLocation:[scanner scanLocation]+1];
	[scanner scanUpToString:@"\r\n" intoString:&crap];
	if ([crap hasPrefix:@":"]) crap = [crap substringFromIndex:1];
	RCChannel *chan = [_channels objectForKey:@"IRC"];
	if (chan) [chan recievedMessage:crap from:@"" type:RCMessageTypeNormal];
	[scanner release];
	// Relay[2626:f803] MSG: :fr.ac3xx.com 002 _m :Your host is fr.ac3xx.com, running version Unreal3.2.9
}

- (void)handle003:(NSString *)servInfos {
	NSScanner *scanner = [[NSScanner alloc] initWithString:servInfos];
	NSString *crap;
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner setScanLocation:[scanner scanLocation]+1];
	[scanner scanUpToString:@"\r\n" intoString:&crap];
    
	if ([crap hasPrefix:@":"]) crap = [crap substringFromIndex:1];
	RCChannel *chan = [_channels objectForKey:@"IRC"];
	if (chan) [chan recievedMessage:crap from:@"" type:RCMessageTypeNormal];
	[scanner release];
	// Relay[2626:f803] MSG: :fr.ac3xx.com 003 _m :This server was created Fri Dec 23 2011 at 01:21:01 CET
}

- (void)handle004:(NSString *)othrInfo {
	NSScanner *scanner = [[NSScanner alloc] initWithString:othrInfo];
	NSString *crap;
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner setScanLocation:[scanner scanLocation]+1];
	[scanner scanUpToString:@"\r\n" intoString:&crap];
	if ([crap hasPrefix:@":"]) crap = [crap substringFromIndex:1];
	RCChannel *chan = [_channels objectForKey:@"IRC"];
	if (chan) [chan recievedMessage:crap from:@"" type:RCMessageTypeNormal];
	[scanner release];
	// Relay[2626:f803] MSG: :fr.ac3xx.com 004 _m fr.ac3xx.com Unreal3.2.9 iowghraAsORTVSxNCWqBzvdHtGp 
}

- (void)handle005:(NSString *)useInfo {
	NSScanner *scanr = [[NSScanner alloc] initWithString:useInfo];
	NSString *crap;
	NSString *args;
	[scanr scanUpToString:@" " intoString:&crap];
	[scanr scanUpToString:@" " intoString:&crap];
	[scanr scanUpToString:@" " intoString:&crap];
	[scanr scanUpToString:@" " intoString:&args];
	NSArray *argsArray = [args componentsSeparatedByString:@" "];
	NSLog(@"Meh. %@", argsArray);
	for (NSString *arg in argsArray) {
		if ([arg hasPrefix:@"TOPICLEN"]) {
		}
		else if ([arg hasPrefix:@"STATUSMSG"]) {
			maxStatusLength = [[arg substringFromIndex:[@"STATUSMSG" length]] intValue];
		}
		else if ([arg hasPrefix:@"CHANTYPES"]) {
			
		}
		else if ([arg hasPrefix:@"PREFIX"]) {
			NSScanner *scanr = [[NSScanner alloc] initWithString:arg];
			NSString *crap;
			NSString *mds;
			[scanr scanUpToString:@")" intoString:&crap];
			[scanr scanUpToString:@"" intoString:&mds];
			[scanr release];
			self.userModes = mds;
		}
		else {
			NSLog(@"NO SUPPORT FOR %@ YET. :/", arg);
		}	
	}
	[scanr release];
	// Relay[2794:f803] MSG: :fr.ac3xx.com 005 _m WALLCHOPS WATCH=128 WATCHOPTS=A SILENCE=15 MODES=12 CHANTYPES=# PREFIX=(qaohv)~&@%+ CHANMODES=beI,kfL,lj,psmntirRcOAQKVCuzNSMTGZ NETWORK=ROXnet CASEMAPPING=ascii EXTBAN=~,qjncrR ELIST=MNUCT STATUSMSG=~&@%+ :are supported by this server
}

- (void)handle251:(NSString *)infos {
	NSScanner *scanner = [[NSScanner alloc] initWithString:infos];
	NSString *crap;
	@try {
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner setScanLocation:[scanner scanLocation]+1];
		[scanner scanUpToString:@"\r\n" intoString:&crap];
	}
	@catch (NSException *exception) {
		NSLog(@"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF %s", (char *)_cmd);
	}
	if ([crap hasPrefix:@":"]) crap = [crap substringFromIndex:1];
	RCChannel *chan = [_channels objectForKey:@"IRC"];
	if (chan) [chan recievedMessage:crap from:@"" type:RCMessageTypeNormal];
	[scanner release];
	// Relay[3067:f803] MSG: :fr.ac3xx.com 251 _m :There are 1 users and 4 invisible on 1 servers
}

- (void)handle252:(NSString *)opsOnline {
	NSScanner *scanner = [[NSScanner alloc] initWithString:opsOnline];
	NSString *crap;
	@try {
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner setScanLocation:[scanner scanLocation]+1];
		[scanner scanUpToString:@"\r\n" intoString:&crap];
	}
	@catch (NSException *exception) {
		NSLog(@"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF %s", (char *)_cmd);
	}
	if ([crap hasPrefix:@":"]) crap = [crap substringFromIndex:1];
	RCChannel *chan = [_channels objectForKey:@"IRC"];
	if (chan) [chan recievedMessage:crap from:@"" type:RCMessageTypeNormal];
	[scanner release];
	// :irc.saurik.com 252 _m 2 :operator(s) online
}

- (void)handle332:(NSString *)topic {
	NSScanner *_scanner = [[NSScanner alloc] initWithString:topic];
	NSString *crap = @"_";
	NSString *to = crap;
	NSString *room = to;
	NSString *_topic = room;
	[_scanner scanUpToString:@" " intoString:&crap];
	[_scanner scanUpToString:@" " intoString:&crap];
	[_scanner scanUpToString:@" " intoString:&to];
	[_scanner scanUpToString:@" " intoString:&room];
	[_scanner scanUpToString:@"\r\n" intoString:&_topic];
    if ([_topic hasPrefix:@":"]) {
        _topic = [_topic substringFromIndex:1];
    }
    NSLog(@"Setting topic [%@]", _topic);
	[[self channelWithChannelName:room ifNilCreate:YES] recievedMessage:_topic from:nil type:RCMessageTypeTopic];
	// :irc.saurik.com 332 _m #bacon :Bacon | where2start? kitchen | Canadian Bacon? get out. | WE SPEAK: BACON, ENGLISH, PORTUGUESE, DEUTSCH. | http://blog.craftzine.com/bacon-starry-night.jpg THIS IS YOU ¬†
	[_scanner release];
}

- (void)handle250:(NSString *)countr {
	// :hubbard.freenode.net 250 Guest01 :Highest connection count: 3549 (3548 clients) (177981 connections received)	
}

- (void)handle253:(NSString *)unknown {
	//:hubbard.freenode.net 253 Guest01 3 :unknown connection(s)	
}

- (void)handle254:(NSString *)rooms {
	// number of channels active
}

- (void)handle255:(NSString *)clients {
	// number of clients. 
}

- (void)handle265:(NSString *)local {
	// Relay[2794:f803] MSG: :fr.ac3xx.com 265 _m :Current Local Users: 5  Max: 7
}

- (void)handle266:(NSString *)global {
	// Relay[2794:f803] MSG: :fr.ac3xx.com 266 _m :Current Global Users: 5  Max: 6
}

- (void)handle305:(NSString *)athreeo_five {
	NSLog(@"Implying this is a znc.");
	NSLog(@"YAY I'M NO LONGER AWAY.");
	if ([[[[[RCNavigator sharedNavigator] currentPanel] channel] delegate] isEqual:self]) {
		[[[RCNavigator sharedNavigator] currentPanel] postMessage:@"You are no longer being marked as away" withType:RCMessageTypeTopic	highlight:NO];
	}
    
}

- (void)handle306:(NSString *)znc {
	NSLog(@"Implying this is a znc.");
	NSScanner *scanner = [[NSScanner alloc] initWithString:znc];
	NSString *crap;
	NSString *cmd;
	NSString *me;
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&cmd];
	[scanner scanUpToString:@" " intoString:&me];
	useNick = [me retain];
	[scanner release];
	
	// :fr.ac3xx.com 305 MaxZNC :You are no longer marked as being away
}

- (void)handle322:(NSString *)threetwotwo {
	if (!namesCallback) return;
	NSScanner *hi = [[NSScanner alloc] initWithString:threetwotwo];
	NSString *crap = NULL;
	NSString *chan = NULL;
	NSString *count = NULL;
	NSString *topicModes = NULL;
	[hi scanUpToString:useNick intoString:&crap];
	[hi scanUpToString:@" " intoString:&crap];
	[hi scanUpToString:@" " intoString:&chan];
	[hi scanUpToString:@" " intoString:&count];
	[hi scanUpToString:@"\r\n" intoString:&topicModes];
	chan = [chan stringByReplacingOccurrencesOfString:@" " withString:@""];
	count = [chan stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSLog(@"eeee %@:%@:%@",chan,count,topicModes);
	[hi release];
	// :irc.saurik.com 322 mx_ #testing 1 :[+nt]
}

- (void)handle331:(NSString *)noTopic {
    [self handle332:noTopic];
	// Relay[18195:707] MSG: :irc.saurik.com 331 _m #kk :No topic is set.
}

- (void)handle333:(NSString *)numbers {
	// :irc.saurik.com 333 _m #bacon Bacon!~S_S@adsl-184-33-54-96.mia.bellsouth.net 1329680840
}

- (void)handle353:(NSString *)_users {
    
	NSScanner *scanner = [[NSScanner alloc] initWithString:_users];
	NSString *crap;
	NSString *me;
	NSString *room;
	NSString *users;
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&me];
	[scanner scanUpToString:@" " intoString:&crap];
	[scanner scanUpToString:@" " intoString:&room];
	[scanner scanUpToString:@"\r\n" intoString:&users];
	if ([users length] > 1) {
		users = [users substringFromIndex:1];
		NSArray *_someUsers = [users componentsSeparatedByString:@" "];
		RCChannel *chan = [self channelWithChannelName:room];
		if (chan) {
			for (NSString *user in _someUsers) {
				[chan setUserJoined:user];
			}
		}
	}
	[scanner release];
    //	add users to room listing..
}
- (void)handle366:(NSString *)end {
	// end of /NAMES list
}

- (void)handle375:(NSString *)motd {
	if (![[RCNetworkManager sharedNetworkManager] _printMotd]) return;
	NSScanner *scanner = [[NSScanner alloc] initWithString:motd];
	NSString *crap;
	@try {
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@"\r\n" intoString:&crap];
        if ([crap hasPrefix:@":"]) crap = [crap substringFromIndex:1];
        RCChannel *chan = [_channels objectForKey:@"IRC"];
        if (chan) [chan recievedMessage:crap from:@"MOTD" type:RCMessageTypeNormal];
	}
	@catch (NSException *exception) {
		NSLog(@"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF %s", (char *)_cmd);
	}
	[scanner release];
	// :irc.saurik.com 375 _m :irc.saurik.com message of the day
}

- (void)handle372:(NSString *)noMotd {
	if (![[RCNetworkManager sharedNetworkManager] _printMotd]) return;
	NSScanner *scanner = [[NSScanner alloc] initWithString:noMotd];
	NSString *crap;
	@try {
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner scanUpToString:@" " intoString:&crap];
		[scanner setScanLocation:[scanner scanLocation]+1];
		[scanner scanUpToString:@"\r\n" intoString:&crap];
	}
	@catch (NSException *exception) {
		NSLog(@"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF %s", (char *)_cmd);
	}
	if ([crap hasPrefix:@":"]) crap = [crap substringFromIndex:1];
	RCChannel *chan = [_channels objectForKey:@"IRC"];
	if (chan) [chan recievedMessage:crap from:@"MOTD" type:RCMessageTypeNormal];
	[scanner release];
	// :irc.saurik.com 372 _m :- Please edit /etc/inspircd/motd
}

- (void)handle376:(NSString *)endOfMotd {
	// :irc.saurik.com 376 _m :End of message of the day.
}

- (void)handle401:(NSString *)blasphemey {
	// no such nick/channel
}

- (void)handle403:(NSString *)blasphemey {
	// no such channel
}

- (void)handle420:(NSString *)blunt {
	NSLog(@"DAFUQ %@", blunt);
}

- (void)handle421:(NSString *)unknown {
	// means we sent a message that is so illogical, fuck you
	NSString *crap = NULL;
	NSString *msg = nil;
	NSScanner *scan = [[NSScanner alloc] initWithString:unknown];
	[scan scanUpToString:@"421" intoString:&crap];
	[scan scanUpToString:@" " intoString:&crap];
	[scan scanUpToString:@" " intoString:&crap];
	[scan scanUpToString:@":" intoString:&msg];
	RCChannel *chan = [_channels objectForKey:@"IRC"];
	[chan recievedMessage:[NSString stringWithFormat:@"Error(421): %@ Unknown Command", [msg uppercaseString]] from:nil type:RCMessageTypeError];
	NSLog(@"Unknown : %@ BYTES: %@", unknown, [unknown dataUsingEncoding:NSUTF8StringEncoding]);
	[scan release];
}

- (void)handle422:(NSString *)motd {
	NSLog(@"Ohai. %@", motd);
}

- (void)handle433:(NSString *)use {
	// nick is in use.
	useNick = [[useNick stringByAppendingString:@"_"] retain]; // set to autorelease, so retain'd copy will be released, and it will be set back to normal. :D
	[self sendMessage:[@"NICK " stringByAppendingString:useNick] canWait:NO];
}

- (void)handleNOTICE:(NSString *)notice {
	NSScanner *_scans = [[NSScanner alloc] initWithString:notice];
	NSString *from = @"_";
	NSString *cmd = from;
	NSString *to = cmd;
	NSString *msg = to;
	[_scans scanUpToString:@" " intoString:&from];
	[_scans scanUpToString:@" " intoString:&cmd];
	[_scans scanUpToString:@" " intoString:&to];
	if ([to isEqualToStringNoCase:@"Auth"]) {
		[_scans release];
		return;
	}
	RCParseUserMask(from, &from, nil, nil);
	[_scans scanUpToString:@"\r\n" intoString:&msg];
	if ([nick isEqualToString:useNick]) {
		msg = [msg substringFromIndex:1];
	}
	from = [from substringFromIndex:1];
	if ([[RCNavigator sharedNavigator] currentPanel]) {
		if ([[[[[RCNavigator sharedNavigator] currentPanel] channel] delegate] isEqual:self]) {
			[[[[RCNavigator sharedNavigator] currentPanel] channel] recievedMessage:msg from:from type:RCMessageTypeNotice];
		}
		else {
			goto end;
		}
	}
	else {
	end:{
		RCChannel *chan = [_channels objectForKey:@"IRC"];
		[chan recievedMessage:msg from:from type:RCMessageTypeNotice];
	}
	}
	
	[_scans release];
	//:Hackintech!Hackintech@2FD03E27.3D6CB32E.E0E5D6BD.IP NOTICE __m__ :HI
}

- (void)handlePRIVMSG:(NSString *)privmsg {
	NSScanner *_scanner = [[NSScanner alloc] initWithString:privmsg];
	NSString *from = @"";
	NSString *cmd = from; // will be unused.
	NSString *room = from;
	NSString *msg = from;
	[_scanner scanUpToString:@" " intoString:&from];
	[_scanner scanUpToString:@" " intoString:&cmd];
	[_scanner scanUpToString:@" " intoString:&room];
	[_scanner scanUpToString:@"\r\n" intoString:&msg];
	msg = [msg substringFromIndex:1];
	from = [from substringFromIndex:1];
	RCParseUserMask(from, &from, nil, nil);
	if ([msg hasPrefix:@"\x01"] && [msg hasSuffix:@"\x01"]) {
		msg = [msg substringFromIndex:1];
        msg = [msg substringToIndex:[msg length]-1];
		if ([msg hasPrefix:@"PING"]) {
			[self handlePING:privmsg];
		}
		else if ([msg hasPrefix:@"TIME"] 
				 || [msg hasPrefix:@"VERSION"] 
				 || [msg hasPrefix:@"USERINFO"] 
				 || [msg hasPrefix:@"CLIENTINFO"]) {
			[self handleCTCPRequest:privmsg];
		}
		else if ([msg hasPrefix:@"ACTION"]) {
			if ([msg length] > 7) {
				msg = [msg substringWithRange:NSMakeRange(7, msg.length-8)];
				[((RCChannel *)[self channelWithChannelName:room]) recievedMessage:msg from:from type:RCMessageTypeAction];
			}
			[_scanner release];
			return;
		}
	}
	else {
		if ([room isEqualToString:useNick]) {
			// privmsg or some other mechanical contraptiona.. :(
			room = from;
		}
		if (![self channelWithChannelName:room]) {
			// magicall.. 0.0
			// has to be a private message.
			// Reasoning: 
			// if we are registered to events from a channel,
			// we must have sent JOIN #channel;
			// which we have caught, and added the RCChannel already.
			[self addChannel:room join:YES];
		}
		// fuck this shit.
		[((RCChannel *)[self channelWithChannelName:room]) recievedMessage:msg from:from type:RCMessageTypeNormal];
		// tell the channel a message was recieved. P:
	}
	[_scanner release];
}
- (void)handleINVITE:(NSString *)invite {
    
    NSRange channelRange = [invite rangeOfString:@"#"];
    
    if (channelRange.location == NSNotFound)
        return;
    
    NSRange finalRange = NSMakeRange(channelRange.location, invite.length-channelRange.location);    
    NSString *channel = [invite substringWithRange:finalRange];
    
    [self addChannel:channel join:YES];
}
- (void)handleKICK:(NSString *)aKick {
	// [NSString stringWithFormat:@"%@ %@", from, msg]
	// sending the from, must be User kicked user, and msg must be the reason, 
	// so [chann recievedEvent:RCEventTypeKickBlah from:[NSString stringWithFormat:@"user kicked user", arg1, arg1] message:reason];
}

- (void)handleNICK:(NSString *)nickChange {
	
}

- (void)handleCTCPRequest:(NSString *)_request {
	NSScanner *_sc = [[NSScanner alloc] initWithString:_request];
	NSString *_from = @"_";
	NSString *cmd = _from;
	NSString *to = cmd;
	NSString *request = to;
	NSString *extra = request;
	[_sc setScanLocation:1];
	[_sc scanUpToString:@" " intoString:&_from];
	[_sc scanUpToString:@" " intoString:&cmd];
	[_sc scanUpToString:@" " intoString:&to];
	[_sc scanUpToString:@" " intoString:&request];
	RCParseUserMask(_from, &_from, nil, nil);
    if ([request hasPrefix:@":"]) {
        request = [request substringFromIndex:1];
    }
    if (![request hasPrefix:@"\x01"]) {
        return;
    }
    if (![request hasSuffix:@"\x01"]) {
        return;
    }
    request = [request substringFromIndex:1];
    request = [request substringToIndex:[request length]-1];
    int vdx = [request rangeOfString:@" "].location;
    if (vdx == NSNotFound) {
        vdx = [request length];
    }
    NSString* command = [request substringToIndex:vdx];
	NSLog(@"Meh. %@", command);
	if ([command isEqualToString:@"TIME"]) 
		extra = [NSString stringWithFormat:@"%@", [NSDate date]];
	else if ([command isEqualToString:@"VERSION"]) 
		extra = @"Relay 1.0";
	else if ([command isEqualToString:@"USERINFO"]) 
		extra = @"";
	else if ([command isEqualToString:@"CLIENTINFO"]) 
		extra = @"CLIENTINFO VERSION CLIENTINFO USERINFO PING TIME UPTIME";
	else 
		NSLog(@"WTF?!?!! %@", command);
	[self sendMessage:[@"NOTICE " stringByAppendingFormat:@"%@ :\x01%@ %@\x01", _from, command, extra]];
	[_sc release];
}

- (void)handlePART:(NSString *)parted {
	NSScanner *_scanner = [[NSScanner alloc] initWithString:parted];
	NSString *user = @"_";
	NSString *cmd = user;
	NSString *room = cmd;
	NSString *_nick = room;
	NSString *msg = _nick;
	[_scanner scanUpToString:@" " intoString:&user];
	[_scanner scanUpToString:@" " intoString:&cmd];
	[_scanner scanUpToString:@" " intoString:&room];
	[_scanner scanUpToString:@"\r\n" intoString:&msg];
	user = [user substringFromIndex:1];
	if ([msg hasPrefix:@":"]) {
		msg = [msg substringFromIndex:1];
	}
	if ([msg isEqualToString:@"_"]) {
		msg = @"";
	}
	msg = [msg stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
	NSLog(@"fuck fuck //%@ //%@ //%@\\//%@\\//%@ ", parted, user, cmd, room, msg);
	RCParseUserMask(user, &_nick, nil, nil);
	if ([_nick isEqualToString:useNick]) {
		NSLog(@"I went byebye. Notify the police");
		[_scanner release];
		return;
	}
	else {
		[[self channelWithChannelName:room] recievedMessage:msg from:_nick type:RCMessageTypePart];
	}
	[_scanner release];
}

- (void)handleJOIN:(NSString *)join {
	// add user unless self
	NSScanner *_scanner = [[NSScanner alloc] initWithString:join];
	NSString *user = @"_";
	NSString *cmd = user;
	NSString *room = cmd;
	NSString *_nick = room;
	[_scanner scanUpToString:@" " intoString:&user];
	[_scanner scanUpToString:@" " intoString:&cmd];
	[_scanner scanUpToString:@" " intoString:&room];
	user = [user substringFromIndex:1];
	if ([room hasPrefix:@" "]) room = [room substringFromIndex:1];
	if ([room hasPrefix:@":"]) room = [room substringFromIndex:1];
	room = [room stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
	RCParseUserMask(user, &_nick, nil, nil);
	if ([_nick isEqualToString:useNick]) {
		[self addChannel:room join:NO];
		[self sendMessage:[NSString stringWithFormat:@"NAMES %@\r\nTOPIC %@", room, room]];
		[[self channelWithChannelName:room] setSuccessfullyJoined:YES];
	}
	else {
		[[self channelWithChannelName:room] recievedMessage:nil from:_nick type:RCMessageTypeJoin];
	}
	[_scanner release];
}

- (void)handleQUIT:(NSString *)quitter {
	NSScanner *scannr = [[NSScanner alloc] initWithString:quitter];
	NSString *fullHost;
	NSString *user;
	NSString *cmd;
	NSString *msg;
	[scannr scanUpToString:@" " intoString:&fullHost];
	[scannr scanUpToString:@" " intoString:&cmd];
	[scannr scanUpToString:@"\r\n" intoString:&msg];
	fullHost = [fullHost substringFromIndex:1];
	if ([msg length] > 1) {
		msg = [msg substringFromIndex:1];
	}
	RCParseUserMask(fullHost, &user, nil, nil);
	for (NSString *channel in [_channels allKeys]) {
		RCChannel *chan = [self channelWithChannelName:channel];
		[chan recievedMessage:msg from:user type:RCMessageTypeQuit];
	}
	[scannr release];
}

- (void)handleMODE:(NSString *)_modes {
	_modes = [_modes substringFromIndex:1];
	NSScanner *scanr = [[NSScanner alloc] initWithString:_modes];
	NSString *settr;
	NSString *cmd;
	NSString *room;
	NSString *modes;
	NSString *user = nil;
	[scanr scanUpToString:@" " intoString:&settr];
	[scanr scanUpToString:@" " intoString:&cmd];
	[scanr scanUpToString:@" " intoString:&room];
	[scanr scanUpToString:@" " intoString:&modes];
	[scanr scanUpToString:@"\r\n" intoString:&user];
	RCParseUserMask(settr, &settr, nil, nil);
	RCChannel *chan = [self channelWithChannelName:room];
	if (chan) {
		if ([room isEqualToString:useNick]) {
			[scanr release];
			return;
		}
		if (!user) {
			[chan recievedMessage:[NSString stringWithFormat:@"sets mode %@", modes] from:settr type:RCMessageTypeMode];
			[scanr release];
			return;
		}
		[chan recievedMessage:[NSString stringWithFormat:@"sets mode %@ %@", modes, user] from:settr type:RCMessageTypeMode];
		[chan setMode:modes forUser:user];
		
	}
	[scanr release];
	// Relay[2626:f803] MSG: :ac3xx!ac3xx@rox-103C7229.ac3xx.com MODE #chat +o _m
}

- (void)handlePING:(NSString *)pong {
	NSLog(@"Ping");
	NSLog(@"Pong");
	if ([pong hasPrefix:@"PING "]) {
		[self sendMessage:[@"PONG " stringByAppendingString:[pong substringFromIndex:5]] canWait:NO];
	}
	else {
		NSScanner *scannr = [[NSScanner alloc] initWithString:pong];
		NSString *from = @"_";
		NSString *cmd = from;
		NSString *to = from;
		NSString *msg = to;
		NSString *user = msg;
		[scannr setScanLocation:1];
		[scannr scanUpToString:@" " intoString:&from];
		[scannr scanUpToString:@" " intoString:&cmd];
		[scannr scanUpToString:@" " intoString:&to];
		[scannr scanUpToString:@" :" intoString:&msg];
        NSLog(@"<%@>", msg);
		RCParseUserMask(from, &user, nil, nil);
		[self sendMessage:[@"NOTICE " stringByAppendingFormat:@"%@ %@", user, msg]];
		[scannr release];
	}
}

- (void)handlehost:(NSString *)hostInfo {
	RCChannel *chan = [_channels objectForKey:@"IRC"];
	if (chan) {
		[chan recievedMessage:[hostInfo substringFromIndex:1] from:@"" type:RCMessageTypeNormal];
	}
	// :Your host is irc.saurik.com, running version InspIRCd-1.1.18+Gudbrandsdalsost
	// .. ... . .. .. only at irc.saurik.comm
}

- (void)handleTOPIC:(NSString *)topic {
	NSScanner *_scan = [[NSScanner alloc] initWithString:topic];
	NSString *from = @"_";
	NSString *cmd = from;
	NSString *room = cmd;
	NSString *newTopic = room;
	[_scan scanUpToString:@" " intoString:&from];
	[_scan scanUpToString:@" " intoString:&cmd];
	[_scan scanUpToString:@" " intoString:&room];
	[_scan scanUpToString:@"\r\n" intoString:&newTopic];
	newTopic = [newTopic substringFromIndex:1];
	from = [from substringFromIndex:1];
	RCParseUserMask(from, &from, nil, nil);
	[[self channelWithChannelName:room] recievedMessage:newTopic from:from type:RCMessageTypeTopic];
	[_scan release];
}

void RCParseUserMask(NSString *mask, NSString **_nick, NSString **user, NSString **hostmask) {
	if (_nick)
		*_nick = nil;
	if (user)
		*user = nil;
	if (hostmask)
		*hostmask = nil;
	NSScanner *scanr = [NSScanner scannerWithString:mask];
	[scanr scanUpToString:@"!" intoString:_nick];
	if ([scanr isAtEnd]) return;
	[scanr setScanLocation:((int)[scanr scanLocation])+1];
	if (!user) return;
	[scanr scanUpToString:@"@" intoString:user];
	[scanr setScanLocation:((int)[scanr scanLocation])+1];
	if ([scanr isAtEnd]) return;
	if (!hostmask) return;
	[scanr scanUpToString:@"" intoString:hostmask];
}

@end

@implementation CALayer (Haxx)
- (id)_nq:(id)arg1 {
	return nil;
}
@end