//
//  RCChatPanel.m
//  Relay
//
//  Created by Max Shavrick on 2/17/12.
//

#import "RCChatPanel.h"
#import "RCChannel.h"
#import "RCChatController.h"

@implementation RCChatPanel
@synthesize channel;

static NSString *template = nil;
- (id)initWithChannel:(RCChannel *)chan {
	if ((self = [super init])) {
		[self setChannel:chan];
		self.opaque = NO;
		[self setBackgroundColor:[UIColor clearColor]];
		if (!template) {
			template = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"chatview" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil] retain];
		}
		preloadPool = [[NSMutableArray alloc] init];
		self.dataDetectorTypes = (UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber);
		self.delegate = (id <UIWebViewDelegate>)self;
		[[self scrollView] setShowsHorizontalScrollIndicator:NO];
		[[self scrollView] setShowsVerticalScrollIndicator:NO];
        [[self scrollView] setDecelerationRate:UIScrollViewDecelerationRateNormal];
		[self loadHTMLString:template baseURL:[NSURL URLWithString:@""]];
	}
	return self;
}

- (void)scrollToTop {
    [self stringByEvaluatingJavaScriptFromString:@"scrollToTop();"];
}

- (BOOL)webView:(UIWebView *)webView2 shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSString *requestString = [[request URL] absoluteString];
	BOOL openInSafari = YES;
	switch (navigationType) {
		case UIWebViewNavigationTypeReload:
			break;
		case UIWebViewNavigationTypeLinkClicked: {
			NSString *escaped = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			if (openInSafari)
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:escaped]];
			else
				[[RCChatController sharedController] presentWebBrowserViewWithURL:escaped];
			return NO;
			break;
		}
		default:
			return YES;
			break;
	}
	return NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	webViewLoaded = YES;
    @synchronized(preloadPool) {
		for (RCMessageFormatter *ms in preloadPool) {
			[self layoutMessage:ms];
		}
		[preloadPool release];
		preloadPool = nil;
        // FIX THIS WITH SCHEMES
		if ([[RCSchemeManager sharedInstance] isDark])
			[self switchToUITheme:@"DarkUI"];
		else {
			[self switchToUITheme:@"LightUI"];
		}
	}
}

- (void)switchToUITheme:(NSString *)uiTheme {
	[self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"switchUI('%@')", uiTheme]];
}

- (void)layoutMessage:(RCMessageFormatter *)ms {
	if (!webViewLoaded) {
		@synchronized(preloadPool) {
#if LOGALL
			NSLog(@"Adding to preload pool [%@] %@", channel, ms);
#endif
			[preloadPool addObject:ms];
			return;
		}
	}
	[ms retain];
	dispatch_async(dispatch_get_main_queue(), ^ {
		NSString *name = nil;
		if (ms.needsCenter) {
			name = [self stringByEvaluatingJavaScriptFromString:@"createMessage(true);"];
		}
		else {
			name = [self stringByEvaluatingJavaScriptFromString:@"createMessage(false);"];
		}
		(void)[self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"postMessage('%@', '%@', %@)", name, ms.string, ((self.scrollView.tracking || self.scrollView.dragging) ? @"false" : @"true")]];
		
		[ms release];
	});
}

- (void)scrollToBottom {
    [self stringByEvaluatingJavaScriptFromString:@"scrollToBottom();"];
}

- (void)layoutSubviews {
	for (UIView *subv in [[[[[self subviews] objectAtIndex:0] subviews] copy] autorelease]) {
		if ([subv isKindOfClass:[UIImageView class]])
			[subv removeFromSuperview];
	}
}

- (void)postMessage:(NSString *)_message withType:(RCMessageType)type highlight:(BOOL)high {
	[self postMessage:_message withType:type highlight:high isMine:NO];
}

- (void)postMessage:(NSString *)_message withType:(RCMessageType)type highlight:(BOOL)high isMine:(BOOL)mine {
    [_message retain];
	RCMessageFormatter *message = [[RCMessageFormatter alloc] initWithMessage:_message isOld:NO isMine:mine isHighlight:high type:type];
	[message format];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self layoutMessage:message];
		[self setNeedsDisplay];
		[message release];
		[_message release];
	});
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	if ([[RCSchemeManager sharedInstance] isDark]) {
		[UIColorFromRGB(0x353538) set];
	}
	else {
		[UIColorFromRGB(0xf0f0f0) set];
	}
	UIRectFill(rect);
}

- (void)dealloc {
	[super dealloc];
}

@end
