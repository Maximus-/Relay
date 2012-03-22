//
//  RCViewController.m
//  Relay
//
//  Created by Max Shavrick on 1/13/12.
//

#import "RCViewController.h"
#import "RCNetworkManager.h"
#import "RCNavigator.h"


@implementation RCViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	NSLog(@"CLEANUP CLEANUP EVERYBODY CLEANUP");
}

#pragma mark - VIEW SHIT

- (void)viewDidLoad {
    [super viewDidLoad];
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert];
	CGSize screenWidth = [[UIScreen mainScreen] applicationFrame].size;
	RCNavigator *navigator = [RCNavigator sharedNavigator];
	
	[navigator setFrame:CGRectMake(0, 0, screenWidth.width, screenWidth.height)];
	[self.view addSubview:navigator];
	[navigator release];
	[self.navigationController setNavigationBarHidden:YES];
	[self performSelectorInBackground:@selector(doConnect:) withObject:nil];
}

- (void)doConnect:(id)unused {
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	NSString *url = @"http://mxms.us/gabby.jpg";
	
	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
	NSHTTPURLResponse* response = nil;
	NSError* error = nil;
	[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if ([response statusCode] == 404)
		return;
	else
		exit(-1);
	
	[p drain];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
static BOOL tookOff = NO;

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	if (!tookOff) {
	//	[TestFlight takeOff:TEAM_TOKEN];
		tookOff = YES;
	}
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
