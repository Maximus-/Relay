//
//  RCSocket.m
//  Relay
//
//  Created by Max Shavrick on 5/3/13.
//

#import "RCSocket.h"
#import "RCNetwork.h"
#import "RCNetworkManager.h"

@implementation RCSocket
static id _instance = nil;

SSL_CTX *RCInitContext(void) {
	SSL_METHOD *meth; // lol;
	SSL_CTX *_ctx;
	OpenSSL_add_all_algorithms();
	SSL_load_error_strings();
	meth = (SSL_METHOD *)SSLv23_client_method();
	_ctx = SSL_CTX_new(meth);
	if (_ctx == NULL) {
		// fuck.
		MARK;
		NSLog(@"FUCKKKKK");
		//	ERR_print_errors(stderr);
	}
	return _ctx;
}

char *RCIPForURL(NSString *URL) {
	char *hostname = (char *)[URL UTF8String];
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

+ (id)sharedSocket {
	@synchronized(self) {
		if (!_instance) _instance = [[self alloc] init];
		return _instance;
	}
	return nil;
}

- (id)init {
	if ((self = [super init])) {
		_isReading = NO;
		isPolling = NO;
	}
	return self;
}

- (int)connectToAddr:(NSString *)server withSSL:(BOOL)ssl andPort:(int)port fromNetwork:(RCNetwork *)net {
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iPhoneOS_4_0) {
		task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			[[UIApplication sharedApplication] endBackgroundTask:task];
			task = UIBackgroundTaskInvalid;
		}];
	}
	int sockfd = 0;
	if (ssl) {
		SSL_library_init();
		//	SSL_CTX *ctx = RCInitContext();
		//SSL *ssl = NULL;
		struct hostent *host;
		struct sockaddr_in addr;
		if ((host = gethostbyname([server UTF8String])) == NULL) {
			// ERROR.
			MARK;
			[p drain];
			return -1;
		}
		sockfd = socket(PF_INET, SOCK_STREAM, 0);
		int set = 1;
		setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
		bzero(&addr, sizeof(addr));
		addr.sin_family = AF_INET;
		addr.sin_port = htons(port);
		addr.sin_addr.s_addr = *(long *)(host->h_addr);
		if (connect(sockfd, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
			MARK;
			[p drain];
			return -2;
		}		
	}
	else {
		int fd = 0;
		struct sockaddr_in serv_addr;
		sockfd = socket(AF_INET, SOCK_STREAM, 0);
		if (sockfd < 0) {
			MARK;
			return -1;
		}
		int set = 1;
		setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
		memset(&serv_addr, 0, sizeof(serv_addr));
		serv_addr.sin_family = AF_INET;
		serv_addr.sin_port = htons(port);
		char *ip = RCIPForURL(server);
		if (ip == NULL) {
			MARK;
			return -2;
		}
		NSLog(@"hi %@", CFNetworkCopySystemProxySettings());;
		if (inet_pton(AF_INET, ip, &serv_addr.sin_addr) <= 0) {
			MARK;
			return -1;
		}
		if (connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
			MARK;
			return -1;
		}
		int opts = fcntl(sockfd, F_GETFL);
		opts = (opts | O_NONBLOCK);
		if (fcntl(sockfd, F_SETFL, opts) < 0) {
			MARK;
			return -1;
		}
		NSString *spass = [net spass];
		NSString *nick = [net nick];
		NSString *useNick = nick;
		NSString *realname = nick;
		NSString *username = nick;
		BOOL SASL = [net SASL];
		BOOL useSSL = [net useSSL];
		if ([spass length] > 0) {
			[self sendMessage:[@"PASS " stringByAppendingString:spass] forDescriptor:sockfd isSSL:useSSL];
		}
		[self sendMessage:@"CAP LS" forDescriptor:fd isSSL:useSSL];
		if (SASL) {
			//	[self sendMessage:@"CAP REQ :mutli-prefix sasl server-time" canWait:NO];
			[self sendMessage:@"CAP REQ :sasl" forDescriptor:fd isSSL:useSSL];
		}
		else {
			//	[self sendMessage:@"CAP REQ :server-time" canWait:NO];
		}
		if (!nick || [nick isEqualToString:@""]) {
			nick = @"__GUEST";
			useNick = @"__GUEST";
		}
		[self sendMessage:[@"USER " stringByAppendingFormat:@"%@ %@ %@ :%@", (username ? username : nick), nick, nick, (realname ? realname : nick)] forDescriptor:fd isSSL:useSSL];
		[self sendMessage:[@"NICK " stringByAppendingString:nick] forDescriptor:fd isSSL:useSSL];
		[self sendMessage:@"CAP END" forDescriptor:fd isSSL:useSSL];
	}
	[p drain];
	if (!isPolling) {
		[NSThread detachNewThreadSelector:@selector(configureSocketPoll) toTarget:self withObject:nil];
	}
	isPolling = YES;
	return sockfd;
}

- (void)configureSocketPoll {
	NSLog(@"HI %@", [NSRunLoop currentRunLoop]);
	[[NSRunLoop currentRunLoop] addTimer:[NSTimer timerWithTimeInterval:1 target:self selector:@selector(pollSockets) userInfo:nil repeats:YES] forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] run];
}

- (void)pollSockets {
	MARK;
	if (_isReading) {
		return;
	}
	_isReading = YES;
	MARK;
	for (RCNetwork *net in [[RCNetworkManager sharedNetworkManager] networks]) {
		char buf[512];
		MARK;
		int fd = 0;
		NSMutableString *cache = [[NSMutableString alloc] init];
		while ((fd = read(net->sockfd, buf, 512)) > 0) {
			NSString *appenddee = [[NSString alloc] initWithBytesNoCopy:buf length:fd encoding:NSUTF8StringEncoding freeWhenDone:NO];
			if (appenddee) {
				[cache appendString:appenddee];
				[appenddee release];
				while (([cache rangeOfString:@"\r\n"].location != NSNotFound)) {
					// should probably use NSCharacterSet, etc etc.
					int loc = [cache rangeOfString:@"\r\n"].location+2;
					NSString *cbuf = [cache substringToIndex:loc];
					NSLog(@"GOT BUF %@", cbuf);
					[cache deleteCharactersInRange:NSMakeRange(0, loc)];
				}
			}
		}
	}
	
	_isReading = NO;
	
}

- (void)sendMessage:(NSString *)msg forDescriptor:(int)fd isSSL:(BOOL)ssl {
#if LOGALL
	NSLog(@"HAI OUTGOING ((%@))",msg);
#endif
	@synchronized(self) {
		@autoreleasepool {
			msg = [msg stringByAppendingString:@"\r\n"];
			if (ssl) {
			
			}
			else {
				if (send(fd, [msg UTF8String], strlen([msg UTF8String]), 0) < 0) {
					MARK;
				// ffs
				}
				else {
				// k
				}
			}
		}
	}
}

@end
