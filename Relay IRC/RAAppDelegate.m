//
//  RAAppDelegate.m
//  Relay IRC
//
//  Created by Max Shavrick on 7/20/15.
//  Copyright (c) 2015 Mxms. All rights reserved.
//

#import "RAAppDelegate.h"
#import "RANetworkManager.h"
#import "RAMainViewController.h"
#import "RANavigationBar.h"
#import "RANavigationController.h"

@implementation RAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	[self setupApplicationData];
	[self configureUI];
	
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	RAMainViewController *rcv = [[RAMainViewController alloc] init];
	self.navigationController = [[[RANavigationController alloc] initWithNavigationBarClass:[RANavigationBar class] toolbarClass:[UIToolbar class]] autorelease];
	[self.navigationController setViewControllers:@[rcv]];
	
	[rcv release];
	self.window.rootViewController = self.navigationController;
	[self.window makeKeyAndVisible];
	return YES;
	
	return YES;
}

- (void)setupApplicationData {
	char *hdir = getenv("HOME");
	if (!hdir) {
		NSLog(@"CAN'T FIND HOME DIRECTORY TO LOAD NETWORKS");
		return;
	}
	NSString *absol = [NSString stringWithFormat:@"%s/Documents/Networks.plist", hdir];
	NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:absol]) {
		if (![manager createFileAtPath:absol contents:(NSData *)[NSDictionary dictionary] attributes:NULL]) {
			NSLog(@"Could not create temporary networks property list.");
		}
	}
	[[RANetworkManager sharedNetworkManager] setIsBG:NO];
	[[RANetworkManager sharedNetworkManager] unpack];
}

- (void)configureUI {
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	
	UINavigationBar *nb = [UINavigationBar appearance];
	
	[nb setBackgroundImage:[UIImage imageNamed:@"ios7_mainnavbarbg"] forBarPosition:UIBarPositionTop barMetrics:UIBarMetricsDefault];
	[UIApplication sharedApplication].statusBarStyle = 1;
	[[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
	[[UISwitch appearance] setOnTintColor:UIColorFromRGB(0x65999d)];
	[[UISwitch appearance] setThumbTintColor:UIColorFromRGB(0xe1e1e1)];
	[[UISearchBar appearance] setSearchFieldBackgroundImage:[UIImage imageNamed:@"goodfield"] forState:UIControlStateNormal];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
