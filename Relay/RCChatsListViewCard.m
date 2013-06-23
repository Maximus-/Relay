//
//  RCChatsListViewCard.m
//  Relay
//
//  Created by Max Shavrick on 6/18/13.
//

#import "RCChatsListViewCard.h"
#import "RCChatController.h"
#import "RCNetworkCell.h"
#import "RCNetworkHeaderButton.h"

@implementation RCChatsListViewCard

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		navigationBar = [[RCChatNavigationBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
		[self addSubview:navigationBar];
		[navigationBar release];
		[self setOpaque:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:@"us.mxms.relay.reload" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeNetwork:) name:@"us.mxms.relay.del" object:nil];
		UIButton *fuckFudge = [[UIButton alloc] initWithFrame:CGRectMake(-20, 0, 84, 84)];
		[fuckFudge setImage:[UIImage imageNamed:@"0_adn"] forState:UIControlStateNormal];
		[fuckFudge setImage:[UIImage imageNamed:@"0_adn_pres"] forState:UIControlStateHighlighted];
		[fuckFudge addTarget:[RCChatController sharedController] action:@selector(showNetworkAddViewController) forControlEvents:UIControlEventTouchUpInside];
		_reloading = NO;
		datas = [[RCSpecialTableView alloc] initWithFrame:CGRectMake(0, 44, 320, frame.size.height-44) style:UITableViewStylePlain];
		[datas setDelegate:self];
		[datas setDataSource:self];
		[datas setSeparatorStyle:UITableViewCellSeparatorStyleNone];
		[datas setBackgroundColor:[UIColor clearColor]];
		[datas setTableFooterView:fuckFudge];
		[fuckFudge release];
		[self addSubview:datas];
		[datas release];
		[self setOpaque:YES];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	[UIColorFromRGB(0x29324A) set];
	UIRectFill(rect);
}

- (void)removeNetwork:(NSNotification *)_net {
	// only temporary to test.
	NSLog(@"HI %@", _net);
	RCNetwork *net = [[RCNetworkManager sharedNetworkManager] networkWithDescription:[_net object]];
	[[RCNetworkManager sharedNetworkManager] removeNet:net];
	_reloading = YES;
	[datas reloadData];
	_reloading = NO;
	[datas reloadData];
}

- (void)reloadData {
	_reloading = YES;
	[datas reloadData];
	_reloading = NO;
	[datas reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (_reloading) return 0;
	RCNetwork *net = [[[RCNetworkManager sharedNetworkManager] networks] objectAtIndex:section];
	return (net.expanded ? [[net _channels] count] : 0);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (_reloading) return 0;
	return [[[RCNetworkManager sharedNetworkManager] networks] count];
}

- (RCNetworkCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *ident = @"0_fcell";
	RCNetworkCell *cell = (RCNetworkCell *)[tableView dequeueReusableCellWithIdentifier:ident];
	if (!cell) {
		cell = [[RCNetworkCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident];
	}
	if ([[[RCNetworkManager sharedNetworkManager] networks] count] == 0) {
		[tableView reloadData];
		return cell;
	}
	RCNetwork *net = [[[RCNetworkManager sharedNetworkManager] networks] objectAtIndex:indexPath.section];
	RCChannel *indexChannel = [[net _channels] objectAtIndex:indexPath.row];
	[indexChannel setCellRepresentation:cell];
	[cell setChannel:[indexChannel channelName]];
	[cell setWhite:NO];
	[cell setNewMessageCount:[indexChannel newMessageCount]];
	RCChannel *chan = [[[RCChatController sharedController] currentPanel] channel];
	if ([[net uUID] isEqual:[[chan delegate] uUID]]) {
		if ([cell.channel isEqualToString:[chan channelName]]) {
			[cell setWhite:YES];
		}
	}
	[cell setNeedsDisplay];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if ([[[RCNetworkManager sharedNetworkManager] networks] count] < 1) {
		[tableView reloadData];
		return nil;
	}
	RCNetworkHeaderButton *bts = [[RCNetworkHeaderButton alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
	RCNetwork *use = [[[RCNetworkManager sharedNetworkManager] networks] objectAtIndex:section];
	[bts setSection:section];
	[bts setNetwork:use];
	[bts setBackgroundColor:[UIColor clearColor]];
	[bts addTarget:self action:@selector(headerTapped:) forControlEvents:UIControlEventTouchUpInside];
	BOOL shouldGlow_ = NO;
	for (RCChannel *chan in [use _channels]) {
		if ([chan newMessageCount] > 0) {
			shouldGlow_ = YES;
			break;
		}
	}
	[bts setShowsGlow:shouldGlow_];
	return [bts autorelease];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	RCNetworkCell *cc = (RCNetworkCell *)[tableView cellForRowAtIndexPath:indexPath];
	[cc setWhite:YES];
	[cc setNeedsDisplay];
	RCNetwork *net = [[[RCNetworkManager sharedNetworkManager] networks] objectAtIndex:indexPath.section];
	[[RCChatController sharedController] selectChannel:[cc channel] fromNetwork:net];
	[tableView reloadData];
}

- (void)headerTapped:(RCNetworkHeaderButton *)hb {
	if ([[hb net] expanded]) {
		[hb setSelected:NO];
		[[hb net] setExpanded:NO];
		NSMutableArray *adds = [[NSMutableArray alloc] init];
		for (int i = 0; i < [[[hb net] _channels] count]; i++) {
			[adds addObject:[NSIndexPath indexPathForRow:i inSection:[hb section]]];
		}
		[datas beginUpdates];
		[datas deleteRowsAtIndexPaths:adds withRowAnimation:UITableViewRowAnimationTop];
		[datas endUpdates];
		[adds release];
	}
	else {
		[hb setSelected:YES];
		[[hb net] setExpanded:YES];
		NSMutableArray *adds = [[NSMutableArray alloc] init];
		for (int i = 0; i < [[[hb net] _channels] count]; i++) {
			[adds addObject:[NSIndexPath indexPathForRow:i inSection:[hb section]]];
		}
		[datas beginUpdates];
		[datas insertRowsAtIndexPaths:adds withRowAnimation:UITableViewRowAnimationTop];
		[datas endUpdates];
		[adds release];
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end