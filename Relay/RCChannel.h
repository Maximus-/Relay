//
//  RCChannel.h
//  Relay
//
//  Created by Max Shavrick on 1/23/12.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "RCChatPanel.h"
#import "RCAppDelegate.h"
#import "NSString+Comparing.h"
#import "RCChannelBubble.h"
#import "RCUserListPanel.h"
#import "RCUserTableCell.h"
#import "RCDateManager.h"

@class RCNetwork;
@class RCNavigator;
@interface RCChannel : NSObject <UITableViewDelegate, UITableViewDataSource> {
	NSMutableDictionary *users;
	NSString *channelName;
	NSString *topic;
	RCChatPanel *panel;
	RCUserListPanel *usersPanel;
	BOOL joined;
	BOOL joinOnConnect;
	RCNetwork *delegate;
	RCChannelBubble *bubble;
}
@property (nonatomic, retain) NSString *channelName;
@property (nonatomic, assign) BOOL joinOnConnect;
@property (nonatomic, assign) RCChatPanel *panel;
@property (nonatomic, readonly) NSString *topic;
@property (nonatomic, assign) RCChannelBubble *bubble;
@property (nonatomic, assign) RCUserListPanel *usersPanel;
- (id)initWithChannelName:(NSString *)_name;
- (void)setDelegate:(RCNetwork *)delegate;
- (RCNetwork *)delegate;
- (void)recievedMessage:(NSString *)message from:(NSString *)from type:(RCMessageType)type;
- (void)setUserJoined:(NSString *)joined;
- (void)setSuccessfullyJoined:(BOOL)success;
- (void)setUserLeft:(NSString *)left;
- (void)setMode:(NSString *)modes forUser:(NSString *)user;
- (void)setJoined:(BOOL)joind withArgument:(NSString *)arg1;
- (void)userWouldLikeToPartakeInThisConversation:(NSString *)message;
- (void)peopleParticipateInConversationsNotPartake:(id)hai wtfWasIThinking:(BOOL)thinking;
// yes, seriously. :P spent like 15 minutes and felt this was best suited. 
- (void)parseAndHandleSlashCommand:(NSString *)cmd;
- (void)setMyselfParted;	
- (NSString *)userWithPrefix:(NSString *)prefix pastUser:(NSString *)user;
- (void)setSuccessfullyJoined:(BOOL)success;
NSString *RCUserRank(NSString *user);
UIImage *RCImageForRank(NSString *rank);
UIImage *RCImageForRanks(NSString *ranks, NSString *possible);
NSString *RCMergeModes(NSString *arg1, NSString *arg2);
NSString *RCSymbolRepresentationForModes(NSString *modes);
NSString *RCSterilizeModes(NSString *modes);
BOOL RCIsRankHigher(NSString *rank, NSString *rank2);
@end
