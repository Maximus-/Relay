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
            
        } else {
            return nil;
        }
	}
	else {
        return nil;
    }
}

@end

@implementation RCChatPanel
@synthesize tableView, messages;

- (id)initWithStyle:(UITableViewStyle)style andChannel:(RCChannel *)chan {
	if ((self = [super init])) {
		[self setBackgroundColor:[UIColor clearColor]];
		[self setChannel:chan];
		self.tableView = [[RCTableView alloc] initWithFrame:CGRectMake(0, 0, 320, 343) style:style];
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
		[self.tableView setBackgroundColor:[UIColor clearColor]];
		[self addSubview:tableView];
		[tableView release];
		[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
		messages = [[NSMutableArray alloc] init];
		currentWord = [[NSMutableString alloc] init];
		prev = @"";
		_bar = [[UIView alloc] initWithFrame:CGRectMake(0, 343, 320, 40)];
		[_bar setOpaque:NO];
		[_bar setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"0_input"]]];
		field = [[UITextField alloc] initWithFrame:CGRectMake(15, 5, 295, 31)];
		[field setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
		[field setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
		[field setBorderStyle:UITextBorderStyleNone];
#if USE_PRIVATE
		/*
		char selector[24];
		selector[0] = 's';
		selector[1] = 'e';
		selector[2] = 't';
		selector[3] = 'I';
		selector[4] = 'n';
		selector[5] = 's';
		selector[6] = 'e';
		selector[7] = 'r';
		selector[8] = 't';
		selector[9] = 'i';
		selector[10] = 'o';
		selector[11] = 'n';
		selector[12] = 'P';
		selector[13] = 'o';
		selector[14] = 'i';
		selector[15] = 'n';
		selector[16] = 't';
		selector[17] = 'C';
		selector[18] = 'o';
		selector[19] = 'l';
		selector[20] = 'o';
		selector[21] = 'r';
		selector[22] = ':';
		selector[23] = '\0';
		
		objc_msgSend(field, sel_registerName(selector), UIColorFromRGB(0x4F94EA));
		 */
		[field setInsertionPointColor:UIColorFromRGB(0x4F94EA)];
#endif
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
		postThread = [NSThread currentThread];
		UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(suggestNick:)];
		[field addGestureRecognizer:gesture];
		[gesture release];
    }
    return self;
}

- (void)suggestNick:(UIGestureRecognizer *)gestr {
	UITextRange *range = [field selectedTextRange];
	NSLog(@"Meh. %@", [field textInRange:range]);
	prev = [channel userWithPrefix:currentWord pastUser:prev];
	NSLog(@"Meh. %@", prev);
}

- (void)setChannel:(RCChannel *)_channel {
	channel = _channel;
}
- (RCChannel *)channel {
	return channel;
}

- (void)setFrame:(CGRect)frame {
	[self.tableView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
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

- (BOOL)becomeFirstResponderNoAnimate {
	[self repositionKeyboardForUse:YES animated:NO];
	[field becomeFirstResponder];
	return YES;
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
	if (entry) [tableView setFrame:CGRectMake(0, 0, 320, 384)];
	else [tableView setFrame:CGRectMake(0, 0, 320, 340)];	
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
	if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
		[_bar setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"0_input_l"]]];
	}
	else {
		[_bar setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"0_input"]]];	
	}
	[self.tableView setFrame:CGRectMake(0, 0, _bar.frame.size.width, _bar.frame.origin.y)];
	if (key) if ([messages count] != 0) [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([messages count]-1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
	if (key) {
		if (self.tableView.contentSize.height > 129) {
		}
	}
	else {
	}
}

- (CGRect)frameForInputField:(BOOL)activ {
	if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
		return CGRectMake(0, (activ ? 65 : 227), 480, 40);
	}
	return CGRectMake(0, (activ ? 127 : 345), 320, 40);
}

- (void)postMessage:(NSString *)_message withFlavor:(RCMessageFlavor)flavor highlight:(BOOL)high {
	[self postMessage:_message withFlavor:flavor highlight:high isMine:NO];
}

- (void)postMessage:(NSString *)_message withFlavor:(RCMessageFlavor)flavor highlight:(BOOL)high isMine:(BOOL)mine {
	RCMessage *message = [[RCMessage alloc] init];
	[message setMessage:_message];
	[message setFlavor:flavor];
	[message setHighlight:high];
	[message setIsMine:mine];
	[self performSelectorOnMainThread:@selector(_correctThreadPost:) withObject:message waitUntilDone:NO];
}

- (void)_correctThreadPost:(RCMessage *)_m {
	[messages addObject:_m];
	[_m release];
	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:([messages count]-1) inSection:0]] withRowAnimation:UITableViewRowAnimationMiddle];
	[self.tableView endUpdates];
	if ([messages count] > 2)
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([messages count]-1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *c = [self tableView:_tableView cellForRowAtIndexPath:indexPath];
	[c layoutSubviews];
	float height = (float)c.textLabel.frame.size.height + 4;
	if (height == 4) height += 15;
	return height;
}

- (NSInteger)tableView:(UITableView *)_tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 0.0;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)_tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)_tableView numberOfRowsInSection:(NSInteger)section {
    return [messages count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"0_CELLID";
    RCChatCell *cell = (RCChatCell *)[_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[RCChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    // Configure the cell...
	RCMessage *_message = [messages objectAtIndex:indexPath.row];
//	if ([cell message]) {
//		if (![[cell message] isEqual:_message]) {
			[cell setMessage:_message];
			[cell _textHasBeenSet];
//		}
//	}
//	else {
//		[cell setMessage:_message];
//		[cell _textHasBeenSet];
//	}
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(RCChatCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if ([field isFirstResponder]) [field resignFirstResponder];
}

- (void)dealloc {
	[currentWord release];
	[messages release];
	[super dealloc];
}

@end
