//
//  RCSocket.h
//  Relay
//
//  Created by Max Shavrick on 5/3/13.
//

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <netdb.h>
#include <time.h>
#include <resolv.h>
#include <netdb.h>
#include "openssl/ssl.h"
#include "openssl/err.h"
#include <ifaddrs.h>
#include <sys/ioctl.h>

@class RCNetwork;
@interface RCSocket : NSObject {
	int task;
	float interval;
	NSTimer *tv;
	BOOL _isReading;
	BOOL isPolling;
}
+ (id)sharedSocket;
- (int)connectToAddr:(NSString *)server withSSL:(BOOL)ssl andPort:(int)port fromNetwork:(RCNetwork *)net;
inline SSL_CTX *RCInitContext(void);
@end
