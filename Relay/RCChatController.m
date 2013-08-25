//
//  RCChatController.m
//  Relay
//
//  Created by Max Shavrick on 10/26/12.
//

#import "RCChatController.h"
#import "RCXLChatController.h"
#import "RCPrettyActionSheet.h"
#import "RCAddNetworkController.h"

@implementation RCChatController
@synthesize currentPanel, canDragMainView;
static id _inst = nil;

+ (id)sharedController {
	return _inst;
}

- (id)init {
	NSLog(@"Requires a view controller on initialization to configure the UI.");
	return nil;
}

- (id)initWithRootViewController:(RCViewController *)rc {
	if ((self = [super init])) {
		if (![self isKindOfClass:[RCXLChatController class]]) {
			CGFloat height = [[UIScreen mainScreen] applicationFrame].size.height;
			if (height > 480) {
				[self release];
				self = [[RCXLChatController alloc] initWithRootViewController:rc];
				return self;
			}
		}
		_inst = self;
		[self layoutWithRootViewController:rc];
	}
	return _inst;
}

- (void)setDefaultTitleAndSubtitle {
	[[chatView navigationBar] setTitle:@"Relay"];
	[[chatView navigationBar] setSubtitle:@"Welcome to Relay"];
	[[chatView navigationBar] setNeedsDisplay];
}

- (void)settingsChanged {
	NSString *shouldAutocorrect = [[RCNetworkManager sharedNetworkManager] valueForSetting:AUTOCORRECTION_KEY];
	NSString *shouldCapitalize = [[RCNetworkManager sharedNetworkManager] valueForSetting:AUTOCAPITALIZE_KEY];
	[field setAutocorrectionType:(shouldAutocorrect ? ([shouldAutocorrect boolValue] ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo): UITextAutocorrectionTypeYes)];
	[field setAutocapitalizationType:(shouldCapitalize ? ([shouldCapitalize boolValue] ? UITextAutocapitalizationTypeSentences : UITextAutocapitalizationTypeNone) : UITextAutocapitalizationTypeSentences)];
}

- (void)layoutWithRootViewController:(RCViewController *)rc {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	currentPanel = nil;
	rootView = rc;
	canDragMainView = YES;
	// This doesn't work for views inside the RCAddNetworkController...
	// fix it max
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged) name:SETTINGS_CHANGED_KEY object:nil];
	CGSize frame = [[UIScreen mainScreen] applicationFrame].size;
	bottomView = [[RCChatsListViewCard alloc] initWithFrame:CGRectMake(0, 0, frame.width, frame.height)];
	[rc.view insertSubview:bottomView atIndex:0];
	chatView = [[RCViewCard alloc] initWithFrame:CGRectMake(0, 0, frame.width, frame.height)];
	[rc.view insertSubview:chatView atIndex:1];
	infoView = [[RCTopViewCard alloc] initWithFrame:CGRectMake(frame.width, 0, frame.width, frame.height)];
	[rc.view insertSubview:infoView atIndex:2];
	UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatViewTapped)];
	[chatView addGestureRecognizer:tapG];
	[tapG release];
	UIPanGestureRecognizer *pg = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(userPanned:)];
	[chatView addGestureRecognizer:pg];
	[pg release];
	chatViewHeights[0] = frame.height-83;
	chatViewHeights[1] = frame.height-299;
	[self setDefaultTitleAndSubtitle];
	[[bottomView navigationBar] setTitle:@"Chats"];
	[[bottomView navigationBar] setSuperSpecialLikeAc3xx2:YES];
	[[infoView navigationBar] setTitle:@"Memberlist"];
	[[infoView navigationBar] setSuperSpecialLikeAc3xx2:YES];
	_bar = [[RCTextFieldBackgroundView alloc] initWithFrame:CGRectMake(0, 800, 320, 40)];
	[_bar setOpaque:NO];
	[_bar.layer setZPosition:1000];
	field = [[RCTextField alloc] initWithFrame:CGRectMake(15, 7, 299, 31)];
	[field setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
	[field setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
	[field setKeyboardAppearance:UIKeyboardAppearanceAlert];
	[field setReturnKeyType:UIReturnKeySend];
	[field setTextColor:[UIColor whiteColor]];
	[field setFont:[UIFont fontWithName:@"Helvetica" size:12]];
	[field setMinimumFontSize:17];
	[field setAdjustsFontSizeToFitWidth:YES];
	[field setDelegate:self];
	[_bar addSubview:field];
	[field release];
	suggestLocation = [self suggestionLocation];
	(void)[RCDateManager sharedInstance]; // make sure this exists.
	[[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_CHANGED_KEY object:nil];
}

- (void)themeChanged:(id)notif {
	[(RCAppDelegate *)[UIApp delegate] configureUI];
	[[chatView navigationBar] setNeedsDisplay];
	[chatView setNeedsDisplay];
	[chatView loadNavigationButtons];
	[[infoView navigationBar] setNeedsDisplay];
	[infoView loadNavigationButtons];
	[infoView setNeedsDisplay];
	[[bottomView navigationBar] setNeedsDisplay];
	[bottomView loadNavigationButtons];
	[bottomView setNeedsDisplay];
	[bottomView reloadData];
	[_bar setNeedsDisplay];
	for (RCNetwork *net in [[RCNetworkManager sharedNetworkManager] networks]) {
		for (RCChannel *chan in [net _channels]) {
			[[chan panel] switchToUITheme:[notif object]];
		}
	}
}

- (void)chatViewTapped {
	if ([self isShowingChatListView]) {
		[self closeWithDuration:0.3];
	}
	else {
		if (infoView.frame.origin.x < infoView.frame.size.width) {
			[self popUserListWithDefaultDuration];
		}
	}
}

- (void)statusWindowTapped:(UITapGestureRecognizer *)tp {
	id targetView = nil;
	if (!!hoverView) {
		targetView = hoverView;
	}
	else if ((chatView.frame.origin.x == 0) && (infoView.frame.origin.x == infoView.frame.size.width)) {
		targetView = currentPanel;
	}
	else if (chatView.frame.origin.x > 0) {
		targetView = bottomView;
	}
	else {
		targetView = infoView;
	}
	[targetView scrollToTop];
}

- (void)correctSubviewFrames {
	return;
	CGSize fsize = [[UIScreen mainScreen] applicationFrame].size;
	[bottomView setFrame:CGRectMake(0, bottomView.frame.origin.y, fsize.width, fsize.height)];
	[chatView setFrame:CGRectMake(0, chatView.frame.origin.y, fsize.width, fsize.height)];
	canDragMainView = YES;
	[self setEntryFieldEnabled:YES];
	[currentPanel setFrame:CGRectMake(currentPanel.frame.origin.x, currentPanel.frame.origin.y, fsize.width, fsize.height)];
	/*
	 [[[[navigationController topViewController] navigationItem] leftBarButtonItem] setEnabled:YES];
	 */
	[UIView animateWithDuration:0.25 animations:^ {
		[infoView setFrame:CGRectMake(infoView.frame.size.width, infoView.frame.origin.y, infoView.frame.size.width, infoView.frame.size.height)];
	} completion:^(BOOL fin) {
		[infoView findShadowAndDoStuffToIt];
	}];
}

- (void)showNetworkListOptions {
	// clear all badges
	// connect/disconnect all
	// settings
	RCPrettyActionSheet *sheet = [[RCPrettyActionSheet alloc] initWithTitle:@"Options" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Settings" otherButtonTitles:@"Connect All", @"Disconnect All", @"Clear Badges", nil];
	[sheet setTag:RCALERR_GLOPTIONS];
	[sheet showInView:rootView.view];
	[sheet release];
}

- (void)presentActionSheetInRootView:(RCPrettyActionSheet *)pr {
	[pr showInView:rootView.view];
}

- (void)keyboardWillShow:(NSNotification *)noti {
	CGRect keyboardFrame;
	[[[noti userInfo] valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
	NSNumber *dur = [[noti userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[noti userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	keyboardFrame = [chatView convertRect:keyboardFrame toView:nil];
	CGRect containerFrame = _bar.frame;
	containerFrame.origin.y = chatView.bounds.size.height - (keyboardFrame.size.height + containerFrame.size.height);
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:[dur doubleValue]];
	[UIView setAnimationCurve:[curve intValue]];
	_bar.frame = containerFrame;
	[currentPanel setFrame:CGRectMake(0, currentPanel.frame.origin.y, currentPanel.frame.size.width, _bar.frame.origin.y - 43)];
	[UIView commitAnimations];
	[currentPanel scrollToBottom];
}

- (void)keyboardWillHide:(NSNotification *)noti {
    NSNumber *dur = [[noti userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [[noti userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	CGRect containerFrame = _bar.frame;
	containerFrame.origin.y = chatView.bounds.size.height - containerFrame.size.height;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:[dur doubleValue]];
	[UIView setAnimationCurve:[curve intValue]];
	_bar.frame = containerFrame;
	[currentPanel setFrame:CGRectMake(0, currentPanel.frame.origin.y, currentPanel.frame.size.width, _bar.frame.origin.y - 43)];
	[UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if ([textField.text isEqualToString:@""] || textField.text == nil) return NO;
	
	NSString *appstore_txt = [textField.text retain];
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_async(queue, ^ {
		dispatch_sync(dispatch_get_main_queue(), ^ {
			[[currentPanel channel] userWouldLikeToPartakeInThisConversation:appstore_txt];
			[appstore_txt release];
		});
	});
	[textField setText:@""];
	[[RCNickSuggestionView sharedInstance] dismiss];
	return NO;
}

- (void)nickSuggestionCancelled {
	nickSuggestionDisabled = YES;
	[[RCNickSuggestionView sharedInstance] dismiss];
}

- (CGFloat)suggestionLocation {
	return 184;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if ([[currentPanel channel] isPrivate]) return YES;
	if ([string rangeOfString:@" "].location != NSNotFound) nickSuggestionDisabled = NO;
	if (nickSuggestionDisabled) return YES;
	NSString *text = [[textField text] retain]; // has to be obtained from a main thread.
	UITextField *tf = [textField retain];
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_async(queue, ^ {
		NSString *lolhaiqwerty = text;
		NSRange rr = NSMakeRange(0, range.location + string.length);
		lolhaiqwerty = [lolhaiqwerty stringByReplacingCharactersInRange:range withString:string];
		for (int i = (range.location + string.length-1); i >= 0; i--) {
			if ([lolhaiqwerty characterAtIndex:i] == ' ') {
				rr.location = i + 1;
				rr.length = ((range.location + string.length) - rr.location);
				break;
			}
		}
		NSString *personMayb = [lolhaiqwerty substringWithRange:rr];
#if LOGALL
		NSLog(@"Word of SAY is [%@]", personMayb);
#endif
		if (!personMayb) {
			dispatch_sync(dispatch_get_main_queue(), ^{
				[[RCNickSuggestionView sharedInstance] dismiss];
				[tf release];
				[text release]; // may cause crash.
				return;
			});
		}
		else if ([personMayb length] > 1) {
			NSArray *found = nil;
			if (([personMayb characterAtIndex:0] == '/') && (rr.location == 0)) {
				found = [[RCCommandEngine sharedInstance] commandsMatchingString:[personMayb substringFromIndex:1]];
				rr = NSMakeRange(rr.location + 1, rr.length - 1);
			}
			else found = [[currentPanel channel] usersMatchingWord:personMayb];
			dispatch_sync(dispatch_get_main_queue(), ^{
				if ([found count] > 0) {
					[[RCNickSuggestionView sharedInstance] setRange:rr inputField:tf];
					[chatView insertSubview:[RCNickSuggestionView sharedInstance] atIndex:5];
					[[RCNickSuggestionView sharedInstance] showAtPoint:CGPointMake(10, suggestLocation) withNames:found];
				}
				else {
					[[RCNickSuggestionView sharedInstance] dismiss];
				}
				[tf release];
			});
		}
		else {
			dispatch_sync(dispatch_get_main_queue(), ^{
				[[RCNickSuggestionView sharedInstance] dismiss];
				[tf release];
			});
		}
		[text release]; // may cause crash.
	});
	return YES;
}

- (void)repositionKeyboardForUse:(BOOL)us animated:(BOOL)anim {
	if (anim) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25];
	}
	CGRect main = CGRectMake(0, 43, 320, chatViewHeights[(int)us]+5);
	[currentPanel setFrame:main];
	[_bar setFrame:CGRectMake(0, currentPanel.frame.origin.y-5 + currentPanel.frame.size.height, 320, 40)];
	
	if (anim) [UIView commitAnimations];
	if (!us) {
		[[RCNickSuggestionView sharedInstance] dismiss];
	}
}

- (void)setEntryFieldEnabled:(BOOL)en {
	[field setEnabled:en];
}

- (BOOL)isLandscape {
	// hopefully reliable..
	return [UIApp statusBarFrame].size.width > 320;
}

- (void)menuButtonPressed:(id)unused {
	[self menuButtonPressed:unused withSpeed:0.25];
}

- (void)menuButtonPressed:(id)unused withSpeed:(NSTimeInterval)sped {
	[currentPanel resignFirstResponder];
	CGRect frame = chatView.frame;
	if (frame.origin.x == 0.0) {
		[self openWithDuration:sped];
	}
	else {
		[self closeWithDuration:sped];
	}
}

static RCNetwork *currentNetwork = nil;
// should probably just make UIAlertView subclass.. derp

- (void)showNetworkOptions:(id)arg1 {
	currentNetwork = [[arg1 superview] net];
	RCPrettyActionSheet *sheet = [[RCPrettyActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"What do you want to do for %@?", [currentNetwork _description]] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Edit", @"Duplicate", ([currentNetwork isTryingToConnectOrConnected] ? @"Disconnect" : @"Connect"), nil];
	[sheet setTag:RCALERR_INDVOPTIONS];
	[sheet showInView:rootView.view];
	[sheet release];
}

- (void)presentViewControllerInMainViewController:(UIViewController *)hi {
	UIViewController *rc = [((RCAppDelegate *)[[UIApplication sharedApplication] delegate]) navigationController];
	UINavigationController *ctrl = [[UINavigationController alloc] initWithRootViewController:hi];
	[ctrl setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
	[rc presentModalViewController:ctrl animated:YES];
	[ctrl release];
}

- (void)showNetworkAddViewController {
	RCAddNetworkController *newc = [[RCAddNetworkController alloc] initWithNetwork:nil];
	[self presentViewControllerInMainViewController:newc];
	[newc release];
}

- (void)presentInitialSetupView {
	return;
	RCInitialSetupView *sv = [[RCInitialSetupView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	[sv prepareForDisplay];
	[sv setWindowLevel:7777];
	[sv setHidden:NO];
	[sv setAlpha:5.0];
}

- (void)showDeleteConfirmationForNetwork {
	RCPrettyAlertView *qq = [[RCPrettyAlertView alloc] initWithTitle:@"Are you sure?" message:[NSString stringWithFormat:@"Are you sure you want to delete %@? This action cannot be undone.", [currentNetwork _description]] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
	[qq setTag:DEL_CONFIRM_KEY];
	[qq show];
	[qq release];
}

- (void)userPanned_special:(UIPanGestureRecognizer *)pan {
	if (isLISTViewPresented) return;
	if (pan.state == UIGestureRecognizerStateChanged) {
		CGPoint tr = [pan translationInView:[chatView superview]];
		CGPoint centr = CGPointMake([chatView center].x +tr.x, [chatView center].y);
		if (draggingUserList && [infoView frame].origin.x > [chatView frame].size.width) {
			draggingUserList = NO;
		}
#if LOGALL
		NSLog(@"HI I AM @ %f [LANDSCAPE]", centr.x);
#endif
		if (centr.x < 240 || draggingUserList) {
			
			draggingUserList = YES;
			if (infoView.frame.origin.x > 240) {
				[infoView setCenter:CGPointMake([infoView center].x+tr.x, [infoView center].y)];
			}
			else {
				
			}
			[pan setTranslation:CGPointZero inView:[chatView superview]];
			return;
		}
		if (!draggingUserList) {
			if (canDragMainView) {
				//	if (centr.x <= 595 && centr.x > 285) {
				if (centr.x < 510) {
					[chatView setCenter:centr];
					[pan setTranslation:CGPointZero inView:[chatView superview]];
				}
			}
		}
	}
	else if (pan.state == UIGestureRecognizerStateEnded) {
		if (draggingUserList) {
			if ([pan velocityInView:[chatView superview]].x > 0) {
				[self popUserListWithDuration:0.30];
			}
			else {
				[self pushUserListWithDuration:0.30];
			}
		}
		else {
			if (!canDragMainView) return;
			if ([pan velocityInView:chatView.superview].x > 0) {
				[self openWithDuration:0.30];
			}
			else
				[self closeWithDuration:0.30];
		}
		draggingUserList = NO;
	}
	else if (pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateFailed) {
		[self cleanLayersAndMakeMainChatVisible];
	}
}

- (void)userPanned:(UIPanGestureRecognizer *)pan {
	if ([bottomView isRearranging] || isLISTViewPresented) return;
	if (isLandscape) {
		[self userPanned_special:pan];
		return;
	}
	if (pan.state == UIGestureRecognizerStateChanged) {
		CGPoint tr = [pan translationInView:[chatView superview]];
		CGPoint centr = CGPointMake([chatView center].x +tr.x, [chatView center].y);
		if (draggingUserList && [infoView frame].origin.x > [infoView frame].size.width) {
			draggingUserList = NO;
		}
#if LOGALL
		NSLog(@"HI I AM @ %f", centr.x);
#endif
		if (centr.x < 160 || draggingUserList) {
			
			draggingUserList = YES;
			[infoView setCenter:CGPointMake([infoView center].x+tr.x, [infoView center].y)];
			[pan setTranslation:CGPointZero inView:[chatView superview]];
			return;
		}
		if (!draggingUserList) {
			if (canDragMainView) {
				//	if (centr.x <= 595 && centr.x > 285) {
				[chatView setCenter:centr];
				[pan setTranslation:CGPointZero inView:[chatView superview]];
				//}
			}
		}
	}
	else if (pan.state == UIGestureRecognizerStateEnded) {
		if (draggingUserList) {
			if ([pan velocityInView:[chatView superview]].x > 0) {
				[self popUserListWithDuration:0.30];
			}
			else {
				[self pushUserListWithDuration:0.30];
			}
		}
		else {
			if (!canDragMainView) return;
			if ([pan velocityInView:chatView.superview].x > 0) {
				[self openWithDuration:0.30];
			}
			else
				[self closeWithDuration:0.30];
		}
		draggingUserList = NO;
	}
	else if (pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateFailed) {
		[self cleanLayersAndMakeMainChatVisible];
	}
}

- (void)closeWithDuration:(NSTimeInterval)dr {
	[UIView animateWithDuration:dr animations:^{
		[chatView setFrame:CGRectMake(0, chatView.frame.origin.y, chatView.frame.size.width, chatView.frame.size.height)];
	} completion:^(BOOL fin) {
		[self setEntryFieldEnabled:YES];
		[chatView findShadowAndDoStuffToIt];
	}];
}

- (void)openWithDuration:(NSTimeInterval)dr {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:dr];
	[chatView setFrame:CGRectMake(267, chatView.frame.origin.y, chatView.frame.size.width, chatView.frame.size.height)];
	[chatView findShadowAndDoStuffToIt];
	[UIView commitAnimations];
	[self setEntryFieldEnabled:NO];
}

- (void)pushUserListWithDuration:(NSTimeInterval)dr {
	RCChannel *channel = [currentPanel channel];
	if ([channel isKindOfClass:[RCPMChannel class]]) {
		//	[topView showUserInfoPanel];
		[((RCChatNavigationBar *)[infoView navigationBar]) setSubtitle:nil];
	}
	else if ([channel isKindOfClass:[RCConsoleChannel class]]) {
		[((RCChatNavigationBar *)[infoView navigationBar]) setSubtitle:nil];
		//	[topView showUserListPanel];
	}
	else if ([channel isKindOfClass:[RCChannel class]]) {
		[[infoView navigationBar] setSubtitle:[NSString stringWithFormat:@"%d users in %@", [[channel fullUserList] count], channel]];
		//	[topView showUserListPanel];
	}
	[[infoView navigationBar] setNeedsDisplay];
	[infoView reloadData];
	canDragMainView = NO;
	[infoView prepareToBecomeVisible];
	[chatView setLeftBarButtonItemEnabled:NO];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:dr];
	[infoView setFrame:CGRectMake((isLandscape ? 200 : 52), infoView.frame.origin.y, infoView.frame.size.width, infoView.frame.size.height)];
	[infoView findShadowAndDoStuffToIt];
	[UIView commitAnimations];
	[currentPanel resignFirstResponder];
	[self setEntryFieldEnabled:NO];
}

- (void)popUserListWithDuration:(NSTimeInterval)dr {
	canDragMainView = YES;
	[self setEntryFieldEnabled:YES];
	[chatView setLeftBarButtonItemEnabled:YES];
	[UIView animateWithDuration:dr animations:^ {
		[infoView setFrame:CGRectMake(chatView.frame.size.width, infoView.frame.origin.y, infoView.frame.size.width, infoView.frame.size.height)];
	} completion:^(BOOL fin) {
		[infoView findShadowAndDoStuffToIt];
	}];
}

- (void)pushUserListWithDefaultDuration {
	[self pushUserListWithDuration:0.30];
}

- (void)popUserListWithDefaultDuration {
	[self popUserListWithDuration:0.30];
}

- (CGRect)frameForChatPanel {
	if ([self isLandscape])
		return CGRectMake(0, 43, 480, 213);
	else
		return CGRectMake(0, 43, 320, 376);
}

- (void)userSwiped_specialLikeAc3xx:(UIPanGestureRecognizer *)pan {
	if (isLISTViewPresented) return;
	if (pan.state == UIGestureRecognizerStateChanged) {
		CGPoint tr = [pan translationInView:[chatView superview]];
		CGPoint cr = CGPointMake([infoView center].x + tr.x, infoView.center.y);
		if (cr.x >= 180) {
			[infoView setCenter:cr];
			[pan setTranslation:CGPointZero inView:[chatView superview]];
		}
	}
	else if (pan.state == UIGestureRecognizerStateEnded) {
		if ([pan velocityInView:[chatView superview]].x > 0) {
			[self popUserListWithDuration:0.30];
		}
		else {
			[self pushUserListWithDuration:0.30];
		}
	}
}

- (void)bottomLayerSwiped:(UIPanGestureRecognizer *)pan {
	if (pan.state == UIGestureRecognizerStateChanged) {
		CGPoint tr = [pan translationInView:[chatView superview]];
		CGPoint cr = CGPointMake([chatView center].x + tr.x, chatView.center.y);
		if (cr.x >= 180) {
			[chatView setCenter:cr];
			[pan setTranslation:CGPointZero inView:[chatView superview]];
		}
	}
	else if (pan.state == UIGestureRecognizerStateEnded) {
		if ([pan velocityInView:[chatView superview]].x > 0) {
			[self openWithDuration:0.30];
		}
		else {
			[self closeWithDuration:0.30];
		}
	}
}


- (void)userSwiped_specialLikeFr0st:(UIPanGestureRecognizer *)pan {
	if (![self isLandscape]) {
		[self userPanned:pan];
		return;
	}
	if (pan.state == UIGestureRecognizerStateBegan) {
		
		
	}
	else if (pan.state == UIGestureRecognizerStateEnded) {
		
	}
}

- (void)cleanLayersAndMakeMainChatVisible {
	[self popUserListWithDuration:0.00];
	[self closeWithDuration:0.30];
}

- (void)showMenuOptions:(id)unused {
	if (isLISTViewPresented) return;
	BOOL isConsole =  ([[currentPanel channel] isKindOfClass:[RCConsoleChannel class]]);
	if (isConsole) {
		
	}
	// present custom action sheet here.
}

- (void)animateChannelList {
	[field resignFirstResponder];
	isLISTViewPresented = YES;
	
	hoverView = [[RCChannelListViewCard alloc] initWithFrame:CGRectZero];
	[[hoverView navigationBar] setTitle:@"Channel List"];
	[[hoverView navigationBar] setSubtitle:@"Loading..."];
	[[[currentPanel channel] delegate] sendMessage:@"LIST"];
	[[[currentPanel channel] delegate] setListCallback:hoverView];
	[(RCChannelListViewCard *)hoverView setCurrentNetwork:[[currentPanel channel] delegate]];
	[self presentHoverCardWithView:hoverView];
	[hoverView release];
	if (![[[currentPanel channel] delegate] isTryingToConnectOrConnected]) {
		// do stuff here
	}
}

- (void)dismissChannelList:(UIView *)vc {
	[[[currentPanel channel] delegate] setListCallback:nil];
	[self dismissHoverCardWithView:vc];
	isLISTViewPresented = NO;
}

- (void)presentHoverCardWithView:(UIView *)vc {
	[vc setFrame:CGRectMake(0, 43, chatView.frame.size.width, chatView.frame.size.height-43)];
	RCCuteView *mv = [[RCCuteView alloc] initWithFrame:chatView.frame];
	[mv setBackgroundColor:[UIColor clearColor]];
	CALayer *sch = [[CALayer alloc] init];
	[sch setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:0.4].CGColor];
	[sch setOpacity:0];
	[sch setName:@"0_skc"];
	[sch setFrame:mv.frame];
	[mv.layer addSublayer:sch];
	[sch release];
	[mv addSubview:vc];
	[rootView.view addSubview:mv];
	[mv release];
	
	CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
	[fade setDuration:0.5];
	fade.fromValue = [NSNumber numberWithFloat:0.0f];
	fade.toValue = [NSNumber numberWithFloat:1.0f];
	[fade setRemovedOnCompletion:NO];
	[fade setFillMode:kCAFillModeBoth];
	[fade setAdditive:NO];
	[fade setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position.y"];
	[anim setDuration:0.4];
	anim.fromValue = [NSNumber numberWithFloat:825];
	anim.toValue = [NSNumber numberWithFloat:(rootView.view.frame.size.height > 480 ? 295 : 250)];
	[anim setRemovedOnCompletion:NO];
	[anim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
	[anim setFillMode:kCAFillModeBoth];
	anim.additive = NO;
	[sch addAnimation:fade forKey:@"opacity"];
	[hoverView.layer addAnimation:anim forKey:@"position"];
}

- (void)dismissHoverCardWithView:(UIView *)vc {
	[CATransaction begin];
	[CATransaction setCompletionBlock:^ {
		[vc removeFromSuperview];
	}];
	CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
	[fade setDuration:0.5];
	fade.fromValue = [NSNumber numberWithFloat:1.0f];
	fade.toValue = [NSNumber numberWithFloat:0.0f];
	[fade setRemovedOnCompletion:NO];
	[fade setFillMode:kCAFillModeBoth];
	[fade setAdditive:NO];
	[fade setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position.y"];
	[anim setDuration:0.4];
	anim.fromValue = [NSNumber numberWithFloat:(rootView.view.frame.size.height > 480 ? 295 : 250)];
	anim.toValue = [NSNumber numberWithFloat:825];
	[anim setRemovedOnCompletion:NO];
	[anim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
	[anim setFillMode:kCAFillModeBoth];
	anim.additive = NO;
	CALayer *vs = nil;
	for (CALayer *cs in [[vc layer] sublayers]) {
		if ([[cs name] isEqualToString:@"0_skc"]) {
			vs = cs;
			break;
		}
	}
	[[[[vc subviews] objectAtIndex:0] layer] addAnimation:anim forKey:@"position"];
	[vs addAnimation:fade forKey:@"opacity"];
	[CATransaction commit];
	hoverView = nil;
}

- (void)presentWebBrowserViewWithURL:(NSString *)urlreq {
	[field resignFirstResponder];
	isLISTViewPresented = YES;
	hoverView = [[RCHoverWebBrowser alloc] initWithFrame:CGRectZero];
	[[hoverView navigationBar] setTitle:@"Loading..."];
	[[hoverView navigationBar] setSubtitle:urlreq];
	[self presentHoverCardWithView:hoverView];
	[hoverView release];
}

- (void)deleteCurrentChannel {
	RCPrettyAlertView *confirm = [[RCPrettyAlertView alloc] initWithTitle:@"Are you sure?" message:[NSString stringWithFormat:@"Are you sure you want to remove %@?", [currentPanel channel]] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove", nil];
	[confirm show];
	[confirm release];
}

- (void)leaveCurrentChannel {
	if ([[[currentPanel channel] delegate] isConnected])
		[[currentPanel channel] setJoined:NO withArgument:@"Relay."];
}

- (void)joinOrConnectDependingOnState {
	if ([[[currentPanel channel] delegate] isConnected]) {
		[[currentPanel channel] setJoined:YES withArgument:nil];
	}
	else {
		[[currentPanel channel] setTemporaryJoinOnConnect:YES];
	}
}

- (void)showMemberList {
	[self pushUserListWithDefaultDuration];
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)pan {
	CGPoint translation = [pan translationInView:[chatView superview]];
	return fabs(translation.x) > fabs(translation.y);
}

- (void)rotateToInterfaceOrientation:(UIInterfaceOrientation)oi {
	if (UIInterfaceOrientationIsLandscape(oi)) {
		isLandscape = YES;
		chatView.frame = CGRectMake(chatView.frame.origin.x, chatView.frame.origin.y, rootView.view.frame.size.width, rootView.view.frame.size.height);
		currentPanel.frame = CGRectMake(currentPanel.frame.origin.x, currentPanel.frame.origin.y, chatView.frame.size.width, chatView.frame.size.height);
		infoView.frame = CGRectMake(rootView.view.frame.size.width, infoView.frame.origin.y, infoView.frame.size.width, rootView.view.frame.size.height);
		bottomView.frame = CGRectMake(bottomView.frame.origin.x, bottomView.frame.origin.y, bottomView.frame.size.width, rootView.view.frame.size.height);
		[_bar setFrame:CGRectMake(0, chatView.frame.size.height - _bar.frame.size.height, chatView.frame.size.width, _bar
								  .frame.size.height)];
	}
	else {
		isLandscape = NO;
		chatView.frame = CGRectMake(chatView.frame.origin.x, chatView.frame.origin.y, rootView.view.frame.size.width, rootView.view.frame.size.height - 64);
	}
	// hi.
}

- (BOOL)isShowingChatListView {
	return (chatView.frame.origin.x > 0);
}

- (void)reloadUserCount {
	RCChannel *chan = [currentPanel channel];
	if ([chan isKindOfClass:[RCPMChannel class]] || [chan isKindOfClass:[RCConsoleChannel class]])
		return;
	[[infoView navigationBar] setSubtitle:[NSString stringWithFormat:@"%d users in %@", [[chan fullUserList] count], chan]];
	[[infoView navigationBar] setNeedsDisplay];
}

- (void)selectChannel:(NSString *)channel fromNetwork:(RCNetwork *)_net {
	for (UIView *subv in [[[chatView subviews] copy] autorelease]) {
		if ([subv isKindOfClass:[RCChatPanel class]])
			[subv removeFromSuperview];
	}
	[field resignFirstResponder];
	[self setEntryFieldEnabled:YES];
	RCNetwork *net = _net;
	if (!_net) net = [[currentPanel channel] delegate];
	RCChannel *chan = [net channelWithChannelName:channel];
	[chan setNewMessageCount:0];
	[chan setHasHighlights:NO];
	[((RCChatNavigationBar *)[chatView navigationBar]) setNeedsDisplay];
	if (!chan) {
		NSLog(@"AN ERROR OCCURED. THIS CHANNEL DOES NOT EXIST BUT IS IN THE TABLE VIEW ANYWAYS.");
		return;
	}
	RCChatPanel *panel = [chan panel];
	[panel setFrame:CGRectMake(0, chatView.navigationBar.frame.size.height - 1, 320, chatViewHeights[0]+2)];
	[_bar setFrame:CGRectMake(0, panel.frame.origin.y+panel.frame.size.height-2, _bar.frame.size.width, _bar.frame.size.height)];
	currentPanel = panel;
	[infoView setChannel:chan];
	[chatView insertSubview:panel atIndex:4];
	[panel setNeedsDisplay]; // consider doing this at a different time.
	[((RCChatNavigationBar *)[chatView navigationBar]) setTitle:[chan channelName]];
	NSString *sub = [net _description];
	if (![[net server] isEqualToString:[net _description]])
		sub = [NSString stringWithFormat:@"%@ – %@", [net _description], [net server]];
	[((RCChatNavigationBar *)[chatView navigationBar]) setSubtitle:sub];
	[((RCChatNavigationBar *)[chatView navigationBar]) setNeedsDisplay];
	if (chatView.frame.origin.x > 0)
		[self menuButtonPressed:nil];
	if (!_bar.superview)
		[chatView insertSubview:_bar atIndex:[[chatView subviews] count]];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch ([alertView tag]) {
		case DEL_CONFIRM_KEY:
			if (buttonIndex == 1) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"us.mxms.relay.del" object:[currentNetwork uUID]];
				currentNetwork = nil;
			}
			break;
		default:
			break;
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch ([actionSheet tag]) {
		case RCALERR_GLOPTIONS: {
			if (buttonIndex == 0) {
				RCSettingsViewController *vc = [[RCSettingsViewController alloc] initWithStyle:0];
				[self presentViewControllerInMainViewController:vc];
				[vc release];
				// settings
			}
			else if (buttonIndex == 1) {
				// connect all
				for (RCNetwork *net in [[RCNetworkManager sharedNetworkManager] networks]) {
					[net connect];
				}
			}
			else if (buttonIndex == 2) {
				for (RCNetwork *net in [[RCNetworkManager sharedNetworkManager] networks]) {
					[net disconnect];
				}
				// disconnect all
			}
			else if (buttonIndex == 3) {
				// hm..
				// clear badges
				for (RCNetwork *net in [[RCNetworkManager sharedNetworkManager] networks]) {
					if ([net isConnected]) {
						for (RCChannel *chan in [net _channels]) {
							[chan setNewMessageCount:0];
							[[chan cellRepresentation] setNewMessageCount:0];
							[[chan cellRepresentation] setNeedsDisplay];
						}
					}
				}
				// this may be slow in the future.
				// find a better way to do this.
			}
			else if (buttonIndex == 4) {
				// cancel
			}
			break;
		}
		case RCALERR_INDVOPTIONS: {
			if (buttonIndex == 0) {
				[self showDeleteConfirmationForNetwork];
			}
			else if (buttonIndex == 1) {
				RCAddNetworkController *addNet = [[RCAddNetworkController alloc] initWithNetwork:currentNetwork];
				[self presentViewControllerInMainViewController:addNet];
				[addNet release];
				currentNetwork = nil;
				// edit.
			}
			else if (buttonIndex == 2) {
				RCNetwork *newNet = [currentNetwork uniqueCopy];
				[[RCNetworkManager sharedNetworkManager] addNetwork:newNet];
				[newNet release];
				reloadNetworks();
			}
			else if (buttonIndex == 3) {
				[currentNetwork connectOrDisconnectDependingOnCurrentStatus];
				currentNetwork = nil;
				//connect
			}
			else if (buttonIndex == 4) {
				// cancel.
				// kbye
			}
			break;
		}
	}
}

@end
