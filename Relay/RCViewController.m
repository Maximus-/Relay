//
//  RCViewController.m
//  Relay
//
//  Created by Max Shavrick on 1/13/12.
//

#import "RCViewController.h"

@implementation RCViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - TABLE_VIEW SHIT

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	RCNetwork *net = [[[RCNetworkManager sharedNetworkManager] networks] objectAtIndex:section];
	return [[net channels] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[[RCNetworkManager sharedNetworkManager] networks] count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	RCTableCell *_c = [tableView dequeueReusableCellWithIdentifier:@"0_CELL_0"];
	if (_c == nil) {
		_c = [[[RCTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"0_CELL_0"] autorelease];
		_c.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	RCNetwork *net = [[[RCNetworkManager sharedNetworkManager] networks] objectAtIndex:indexPath.section];
	_c.textLabel.text = [[net channels] objectAtIndex:indexPath.row];
	_c.detailTextLabel.text = [[[net _channels] objectForKey:_c.textLabel.text] lastMessage];
	_c.detailTextLabel.frame = CGRectMake(_c.detailTextLabel.frame.origin.x, _c.detailTextLabel.frame.origin.y, 300, _c.detailTextLabel.frame.size.height);
	return _c;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	RCNetwork *net = [[[RCNetworkManager sharedNetworkManager] networks] objectAtIndex:indexPath.section];
	[self.navigationController pushViewController:[[[net _channels] objectForKey:[(UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath] textLabel].text] panel] animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	RCTableHeaderView *header = [[RCTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 25)];
	[header setNetwork:[[[RCNetworkManager sharedNetworkManager] networks] objectAtIndex:section]];
	return [header autorelease];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60.0;
}

#pragma mark - VIEW SHIT

- (void)viewDidLoad {
	[[NSNotificationCenter defaultCenter] addObserver:[self tableView] selector:@selector(reloadData) name:RELOAD_KEY object:nil];
    [super viewDidLoad];
	self.title = @"Relay";
	[[self view] setBackgroundColor:[UIColor blackColor]];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	[[RCNetworkManager sharedNetworkManager] ircNetworkWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										  @"_m", USER_KEY, 
										  @"_m", NICK_KEY,
										  @"0_m_hai", NAME_KEY,
										  @"privateircftw", S_PASS_KEY,
										  @"", N_PASS_KEY,
										  @"feer", DESCRIPTION_KEY,
										  @"fr.ac3xx.com", SERVR_ADDR_KEY,
										  @"6667", PORT_KEY,
										  [NSNumber numberWithBool:0], SSL_KEY,
										  [NSNumber numberWithBool:1], COL_KEY,
										  [NSArray arrayWithObjects:@"#chat", @"#tttt", nil], CHANNELS_KEY,
										  nil]];
	[[RCNetworkManager sharedNetworkManager] ircNetworkWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																 @"_m", USER_KEY, 
																 @"_m", NICK_KEY,
																 @"0_m_hai", NAME_KEY,
																 @"", S_PASS_KEY,
																 @"", N_PASS_KEY,
																 @"SK", DESCRIPTION_KEY,
																 @"irc.saurik.com", SERVR_ADDR_KEY,
																 @"6667", PORT_KEY,
																 [NSNumber numberWithBool:0], SSL_KEY,
																 [NSNumber numberWithBool:1], COL_KEY,
																 [NSArray arrayWithObjects:@"#bacon", @"#kk", nil], CHANNELS_KEY,
																 nil]];
	
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown));
}

@end
