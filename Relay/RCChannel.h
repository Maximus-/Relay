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
#import "NSString+Utils.h"
#import "RCChannelBubble.h"
#import "RCUserListPanel.h"
#import "RCUserTableCell.h"
#import "RCDateManager.h"

@class RCNetwork;
@class RCNavigator;
@interface RCChannel : NSObject <UITableViewDelegate, UITableViewDataSource> {
	NSString *channelName;
	NSString *topic;
	NSString *password;
	RCChatPanel *panel;
	RCUserListPanel *usersPanel;
	BOOL joined;
	BOOL joinOnConnect;
    BOOL shouldJoin;
	RCNetwork *delegate;
	RCChannelBubble *bubble;
    NSMutableArray *fullUserList;
    NSMutableDictionary *userRanksAdv;
}
@property (nonatomic, retain) NSString *channelName;
@property (nonatomic, assign) BOOL joinOnConnect;
@property (nonatomic, assign) RCChatPanel *panel;
@property (nonatomic, retain) NSString *topic;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) RCChannelBubble *bubble;
@property (nonatomic, assign) RCUserListPanel *usersPanel;
- (void)disconnected:(NSString*)msg;
- (void)changeNick:(NSString*)old toNick:(NSString*)new_;
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
- (BOOL)joined;
// yes, seriously. :P spent like 15 minutes and felt this was best suited. 
- (void)parseAndHandleSlashCommand:(NSString *)cmd;
- (void)setMyselfParted;	
- (NSString *)userWithPrefix:(NSString *)prefix pastUser:(NSString *)user;
- (BOOL)isUserInChannel:(NSString*)user;
- (void)setSuccessfullyJoined:(BOOL)success;
- (BOOL)isPrivate;
- (void)setJoined:(BOOL)joind;
NSString *RCUserRank(NSString *user, RCNetwork* network);
UIImage *RCImageForRank(NSString *rank, RCNetwork* network);
BOOL RCIsRankHigher(NSString *rank, NSString *rank2, RCNetwork* network);
@end
