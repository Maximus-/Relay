//
//  RCNetworkCell.h
//  Relay
//
//  Created by Max Shavrick on 6/22/12.
//

#import <UIKit/UIKit.h>
#import "RCBasicTableViewCell.h"

@interface RCNetworkCell : RCBasicTableViewCell {
	NSString *channel;
	BOOL white;
	BOOL fakeWhite;
	BOOL joined;
	BOOL hasHighlights;
	int newMessageCount;
}
@property (nonatomic, retain) NSString *channel;
@property (nonatomic, assign) BOOL white;
@property (nonatomic, assign) BOOL joined;
@property (nonatomic, assign) BOOL hasHighlights;
@property (nonatomic, assign) int newMessageCount;
@end
