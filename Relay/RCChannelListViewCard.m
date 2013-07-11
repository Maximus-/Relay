//
//  RCChannelListViewCard.m
//  Relay
//
//  Created by Max Shavrick on 6/29/13.
//

#import "RCChannelListViewCard.h"
#import "RCChatController.h"

@implementation RCChannelListViewCard

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[navigationBar setMaxSize:18];
		[navigationBar setNeedsDisplay];
		channelDatas = [[NSMutableArray alloc] init];
		CALayer *cv = [[CALayer alloc] init];
		[cv setContents:(id)[UIImage imageNamed:@"0_nvs"].CGImage];
		[cv setFrame:CGRectMake(0, -46, 320, 46)];
		[self.layer addSublayer:cv];
		[cv release]; 
		channels = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, frame.size.width, frame.size.height-44)];
		[channels setSeparatorStyle:UITableViewCellSeparatorStyleNone];
		[channels setBackgroundColor:UIColorFromRGB(0xDDE0E5)];
		[channels setShowsVerticalScrollIndicator:YES];
		[channels setDelegate:self];
		[channels setDataSource:self];
		[channels setScrollEnabled:YES];
		[self addSubview:channels];
		[channels release];
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (updating) return 0;
	return [channelDatas count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	RCChannelInfoTableViewCell *cc = (RCChannelInfoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"0_CSL"];
	if (!cc) {
		cc = [[[RCChannelInfoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"0_CSL"] autorelease];
	}
	[cc setChannelInfo:[channelDatas objectAtIndex:indexPath.row]];
	[cc setBackgroundColor:[UIColor blackColor]];
	return cc;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 50;
}

- (void)setUpdating:(BOOL)ud {
	updating = ud;
	dispatch_sync(dispatch_get_main_queue(), ^{
		if (!updating) {
			if ([channelDatas count] == 0) {
				[self presentErrorNotificationAndDismiss];
			}
			else {
				[channels reloadData];
				[[self navigationBar] setSubtitle:[NSString stringWithFormat:@"%d Channels", [channelDatas count]]];
				[[self navigationBar] setNeedsDisplay];
			}
		}
	});
}

- (void)presentErrorNotificationAndDismiss {
	RCPrettyAlertView *alrt = [[RCPrettyAlertView alloc] initWithTitle:@"Error" message:@"There was an issue getting the channel list. Please try again in a minute." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
	[alrt show];
	[alrt release];
	[(RCCuteView *)[self superview] dismiss];
}

- (void)recievedChannel:(NSString *)chan withCount:(int)cc andTopic:(NSString *)topics {
	if (!updating) updating = YES;
	RCChannelInfo *ifs = [[RCChannelInfo alloc] init];
	[ifs setChannel:chan];
	[ifs setUserCount:cc];
	if (![topics isEqualToString:@":"])
		[ifs setTopic:topics];
	else
		[ifs setTopic:@"No topic set."];
	NSString *lcnt = [NSString stringWithFormat:@"%d Users", cc];
	CGFloat rsz = 0;
	CGSize szf = [lcnt sizeWithFont:[UIFont systemFontOfSize:12] minFontSize:10 actualFontSize:&rsz forWidth:84 lineBreakMode:NSLineBreakByClipping];
	NSString *nam = chan;
	CGFloat azf = 0;
	[nam sizeWithFont:[UIFont boldSystemFontOfSize:16] minFontSize:8 actualFontSize:&azf forWidth:(320 - (szf.width + 21)) lineBreakMode:NSLineBreakByClipping];
	NSString *set = [NSString stringWithFormat:@"%@ %d Users", chan, cc];
	int lfr = [chan length];
	NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:set];
	UIFont *ft = [UIFont boldSystemFontOfSize:azf];
	[str addAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:ft, UIColorFromRGB(0x444647), nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil]] range:NSMakeRange(0, lfr)];
	UIFont *sft = [UIFont systemFontOfSize:rsz];
	[str addAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:sft, UIColorFromRGB(0x797c7e), nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil]] range:NSMakeRange(lfr, [set length] - lfr)];
	[ifs setAttributedString:str];
	[str release];
	[channelDatas addObject:ifs];
	[ifs release];
}

- (void)dealloc {
	[channelDatas release];
	[super dealloc];
}

@end
