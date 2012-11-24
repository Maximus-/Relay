//
//  RCUserListViewController.m
//  Relay
//
//  Created by Max Shavrick on 11/23/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "RCUserListViewController.h"
#import "RCChatController.h"

@implementation RCUserListViewController

- (id)initWithRootViewController:(UIViewController *)rootViewController {
	if ((self = [super initWithRootViewController:rootViewController])) {
		CALayer *shdw = [[CALayer alloc] init];
		[shdw setName:@"0_fuckingshadow"];
		UIImage *mfs = [UIImage imageNamed:@"0_hzshdw"];
		[shdw setContents:(id)mfs.CGImage];
		[shdw setShouldRasterize:YES];
		[shdw setFrame:CGRectMake(-mfs.size.width+3, 0, mfs.size.width, self.view.frame.size.height)];
		[shdw setHidden:YES];
		[self.view.layer insertSublayer:shdw atIndex:0];
		[shdw release];
		UIButton *back = [[UIButton alloc] init];
		[back setFrame:CGRectMake(0, 0, 41, 31)];
		[back setImage:[UIImage imageNamed:@"0_bmv"] forState:UIControlStateNormal];
		[back setImage:[UIImage imageNamed:@"0_bmv_pres"] forState:UIControlStateHighlighted];
		[back addTarget:[RCChatController sharedController] action:@selector(popUserListWithDefaultDuration) forControlEvents:UIControlEventTouchUpInside];
		UIBarButtonItem *bc = [[UIBarButtonItem alloc] initWithCustomView:back];
		[[[self topViewController] navigationItem] setLeftBarButtonItem:bc];
		[bc release];
		[back release];
		UIPanGestureRecognizer *panr = [[UIPanGestureRecognizer alloc] initWithTarget:[RCChatController sharedController] action:@selector(userSwiped_specialLikeAc3xx:)];
		[self.view addGestureRecognizer:panr];
		[panr release];
		tableView = [[RCSuperSpecialTableView alloc] initWithFrame:CGRectZero];
		[tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
		[tableView setBackgroundColor:[UIColor clearColor]];
		[tableView setDelegate:self];
		[tableView setDataSource:self];
		[self.view addSubview:tableView];
		[tableView release];
	}
	return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	RCUserTableCell *c = (RCUserTableCell *)[tableView dequeueReusableCellWithIdentifier:@"0_usc"];
	if (!c) {
		c = [[[RCUserTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"0_usc"] autorelease];
	}
	c.textLabel.text = @"There are no users in this channel.";
	c.detailTextLabel.text = @":(";
	return c;
}

- (void)setCenter:(CGPoint)ct {
	self.view.center = ct;
	[self findShadowAndDoStuffToIt];
	[self correctTableViewFrame];
	[tableView setFrame:self.view.frame];
}

- (void)findShadowAndDoStuffToIt {
	for (CALayer *sub in [self.view.layer sublayers]) {
		if ([[sub name] isEqualToString:@"0_fuckingshadow"]) {
			[sub setFrame:CGRectMake(sub.frame.origin.x, sub.frame.origin.y, sub.frame.size.width, self.view.frame.size.height)];
			[sub setHidden:(self.view.frame.origin.x >= self.view.frame.size.width)];
			break;
		}
	}
}

- (void)correctTableViewFrame {
	CGRect fr = self.view.frame;
	fr.origin.x = 0;
	fr.origin.y += 44;
	fr.size.height -= 44;
	tableView.frame = fr;
}

- (void)setFrame:(CGRect)frm {
	self.view.frame = frm;
	[self correctTableViewFrame];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	CALayer *bg = [[CALayer alloc] init];
	[bg setContents:(id)([UIImage imageNamed:@"0_cbg"].CGImage)];
	[bg setFrame:CGRectMake(0, 0, 320, 568)];
	[bg setShouldRasterize:YES];
	[self.view.layer insertSublayer:bg atIndex:[self.view.layer.sublayers count]];
	[bg release];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
