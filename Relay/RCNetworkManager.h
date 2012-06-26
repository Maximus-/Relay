//
//  RCNetworkManager.h
//  Relay
//
//  Created by Max Shavrick on 1/13/12.
//

#import <Foundation/Foundation.h>
#import "RCNetwork.h"
#import "RCWelcomeNetwork.h"
#import "RCKeychainItem.h"

@interface RCNetworkManager : NSObject {
	BOOL isBG;
	BOOL saving;
	BOOL _printMotd;
}
@property (nonatomic, assign) BOOL isBG;
@property (nonatomic, readonly) BOOL _printMotd;
+ (RCNetworkManager *)sharedNetworkManager;
- (RCNetwork *)networkWithDescription:(NSString *)_desc;
- (void)ircNetworkWithInfo:(NSDictionary *)info isNew:(BOOL)n;
- (void)addNetwork:(RCNetwork *)net;
- (NSMutableArray *)networks;
- (void)removeNet:(RCNetwork *)net;
- (void)saveNetworks;
- (void)unpack;
- (void)setupWelcomeView;
- (void)_reallySaveChannelData:(id)unused;
@end
