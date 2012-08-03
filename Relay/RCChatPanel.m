//
//  RCChatPanel.m
//  Relay
//
//  Created by Max Shavrick on 2/17/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "RCChatPanel.h"
#import "RCChannel.h"
#import "RCNavigator.h"

@implementation NSObject (Stuff)

- (id)performSelector:(SEL)selector onThread:(NSThread *)aThread withObject:(id)p1 withObject:(id)p2 withObject:(id)p3 withObject:(id)p4 {
    NSMethodSignature *sig = [self methodSignatureForSelector:selector];
    if (sig) {
        NSInvocation* invo = [NSInvocation invocationWithMethodSignature:sig];
        [invo setTarget:self];
        [invo setSelector:selector];
        [invo setArgument:&p1 atIndex:2];
        [invo setArgument:&p2 atIndex:3];
        [invo setArgument:&p3 atIndex:4];
        [invo setArgument:&p4 atIndex:5];
        [invo performSelector:@selector(invoke) onThread:aThread withObject:nil waitUntilDone:NO];
        if (sig.methodReturnLength) {
            id anObject;
            [invo getReturnValue:&anObject];
            return anObject;
		}
		else {
			return nil;
        }
	}
	else {
        return nil;
    }
}

@end

@implementation RCChatPanel
@synthesize messages, channel;

- (id)initWithStyle:(UITableViewStyle)style andChannel:(RCChannel *)chan {
	if ((self = [super init])) {
		[self setBackgroundColor:[UIColor clearColor]];
		[self setChannel:chan];
		mainView = [[RCScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 343)];
		[self addSubview:mainView];
		[mainView release];
		//		self.tableView = [[RCTableView alloc] initWithFrame:CGRectMake(0, 0, 320, 343) style:style];
		//self.tableView.delegate = self;
		//self.tableView.dataSource = self;
		//[self.tableView setBackgroundColor:[UIColor clearColor]];
		//[self addSubview:tableView];
		//[tableView release];
		//[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
		currentWord = [[NSMutableString alloc] init];
		prev = @"";
		_bar = [[RCTextFieldBackgroundView alloc] initWithFrame:CGRectMake(0, 343, 320, 40)];
		[_bar setOpaque:NO];
		//	UIImage *bg = [UIImage imageNamed:@"0_input"];
		//NSLog(@"Meh %@", bg);
		//UIColor *cc = [UIColor colorWithPatternImage:bg];
		//NSLog(@"meh_ %@", cc);
		//[_bar performSelectorOnMainThread:@selector(setBackgroundColor:) withObject:cc waitUntilDone:NO];
		field = [[RCTextField alloc] initWithFrame:CGRectMake(15, 5, 295, 31)];
		[field setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
		[field setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
		[field setBorderStyle:UITextBorderStyleNone];
		[field setKeyboardAppearance:UIKeyboardAppearanceDefault];
		[field setReturnKeyType:UIReturnKeySend];
		[field setFont:[UIFont fontWithName:@"Helvetica" size:12]];
		[field setMinimumFontSize:17];
		[field setAdjustsFontSizeToFitWidth:YES];
		[field setDelegate:self];
		[_bar addSubview:field];
		[field release];
		[self addSubview:_bar];
		[_bar release];
		UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(suggestNick:)];
		[field addGestureRecognizer:gesture];
		[gesture release];
    }
    return self;
}

- (void)suggestNick:(UIGestureRecognizer *)gestr {
	prev = [channel userWithPrefix:currentWord pastUser:prev];
}

- (void)setFrame:(CGRect)frame {
	[_bar setFrame:CGRectMake(0, frame.size.height, frame.size.width, 40)];
	[self repositionKeyboardForUse:[field isFirstResponder] animated:NO];
	[super setFrame:CGRectMake(0, frame.origin.y, frame.size.width, frame.size.height+40)];
}

- (BOOL)isFirstResponder {
	return field.isFirstResponder;
}

- (BOOL)becomeFirstResponder {
	[self repositionKeyboardForUse:YES animated:YES];
	[field becomeFirstResponder];
	return YES;
}

- (void)becomeFirstResponderNoAnimate {
	[self repositionKeyboardForUse:YES animated:NO];
	[field becomeFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[self repositionKeyboardForUse:NO animated:YES];
}

- (BOOL)resignFirstResponder {
	[self repositionKeyboardForUse:NO animated:YES];
	[field resignFirstResponder];
	return YES;
}

- (void)setHidesEntryField:(BOOL)entry {
	[_bar setHidden:entry];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if ([textField.text isEqualToString:@""] || textField.text == nil) return NO;
	[self performSelectorInBackground:@selector(__reallySend:) withObject:textField.text];
	[textField setText:@""];
	return NO;
}

- (void)__reallySend:(NSString *)msg {
	[channel performSelectorOnMainThread:@selector(userWouldLikeToPartakeInThisConversation:) withObject:msg waitUntilDone:NO];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[textField setEnablesReturnKeyAutomatically:!(textField.text != nil && ![textField.text isEqualToString:@""])];
	[self repositionKeyboardForUse:YES animated:YES];
}

- (void)repositionKeyboardForUse:(BOOL)key animated:(BOOL)anim {
	if (anim) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.25];
	}
	[_bar setFrame:[self frameForInputField:key]];
	field.frame = CGRectMake(15, 5, _bar.frame.size.width-30, 31);
	if (anim) [UIView commitAnimations];
		[mainView setFrame:CGRectMake(0, 0, _bar.frame.size.width, _bar.frame.origin.y)];
	[mainView performSelectorInBackground:@selector(prepareToRelaySubviews) withObject:nil];
	[_bar performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}

- (CGRect)frameForInputField:(BOOL)activ {
	if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
		return CGRectMake(0, (activ ? 66 : 227), 480, 40);
	}
	return CGRectMake(0, (activ ? 127 : 345), 320, 40);
}

- (void)postMessage:(NSString *)_message withFlavor:(RCMessageFlavor)flavor highlight:(BOOL)high {
	[self postMessage:_message withFlavor:flavor highlight:high isMine:NO];
}

- (void)postMessage:(NSString *)_message withFlavor:(RCMessageFlavor)flavor highlight:(BOOL)high isMine:(BOOL)mine {
	RCMessage *message = [[RCMessage alloc] initWithMessage:_message isOld:NO isMine:mine isHighlight:high flavor:flavor];
	float *heights = [self calculateHeightForLabel:[message string]];
	[message setMessageHeight:heights[0]];
	[message setMessageHeightLandscape:heights[1]];
	free(heights);
	[self performSelectorOnMainThread:@selector(_correctThreadPost:) withObject:message waitUntilDone:NO];
}

- (void)_correctThreadPost:(RCMessage *)_m {
	[mainView layoutMessage:_m];
}

- (float *)calculateHeightForLabel:(NSMutableAttributedString *)str {
	float *heights = (float *)malloc(sizeof(float *));
	float fake = [str boundingHeightForWidth:316];
	float faker = [str boundingHeightForWidth:476];
	float multiplier = fake/12;
	heights[0] = fake + (multiplier * 3);
	multiplier = faker/12;
	heights[1] = faker + (multiplier * 3);
	return ((float *)heights);
}

#pragma mark - Table view delegate

- (void)dealloc {
	[currentWord release];
	[super dealloc];
}

@end
