//
//  RCPMChannel.h
//  Relay
//
//  Created by Max Shavrick on 3/24/12.
//

#import "RCChannel.h"

@interface RCPMChannel : RCChannel {
	NSString *ipInfo;
	NSString *chanInfos;
	NSString *connectionInfo;
	BOOL partnerIsOnline;
}
@property (nonatomic, retain) NSString *ipInfo;
@property (nonatomic, retain) NSString *chanInfos;
@property (nonatomic, retain) NSString *connectionInfo;
@property (nonatomic, assign) BOOL thirstyForWhois;
@property (nonatomic, assign) BOOL hasWhois;
- (BOOL)isPrivate;
- (void)_reallySetWhois:(NSString *)whois;
- (void)requestWhoisInformation;
- (void)recievedWHOISInformation;
@end
