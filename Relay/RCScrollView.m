//
//  RCScrollView.m
//  Relay
//
//  Created by Max Shavrick on 7/27/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "RCScrollView.h"
#import <CoreText/CoreText.h>
#import "RCAttributedString.h"
#import "RCMessageFormatter.h"
#import "NSString+IRCStringSupport.h"
#import "RCChannel.h"
static NSString* template = nil;

static NSString* str2col[] = {
    @"white", // white
    @"black", // black
    @"navy", // blue
    @"green", // green
    @"red", // red
    @"maroon", // brown
    @"purple", // purple
    @"orange", // orange
    @"yellow", // yellow
    @"lime", // lime
    @"teal", // teal
    @"lightcyan", // light cyan
    @"royalblue", // light blue
    @"fuchsia", // pink
    @"grey", // grey
    @"silver", // light grey
    nil
};
NSString* colorForIRCColor(char irccolor);
NSString* colorForIRCColor(char irccolor)
{
    if (irccolor == -1) {
        return @"default-foreground";
    }
    if (irccolor == -2) {
        return @"default-background";
    }
    if (irccolor >= 16) {
        return @"invalid";
    }
    return str2col[irccolor];
}

@implementation RCScrollView
@synthesize chatpanel;
- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
        /*
         [self setBackgroundColor:[UIColor clearColor]];
         [self setCanCancelContentTouches:YES];
         y = 4;
         self.pagingEnabled = NO;
         shouldScroll = YES;
         stringToDraw = [[NSMutableAttributedString alloc] init];
         self.backgroundColor = [UIColor clearColor];
         self.contentMode = UIViewContentModeRedraw;
         [self setScrollEnabled:YES];
         [self setDelegate:self];
         */
        if (!template) {
            template = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"chatview" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil] retain];
        }
        self.opaque = NO;
        self.dataDetectorTypes = UIDataDetectorTypeNone;
        self.backgroundColor = [UIColor clearColor];
        self.delegate = (id<UIWebViewDelegate>) self;
        preloadPool = [NSMutableArray new];
        [self loadHTMLString:template baseURL:[NSURL URLWithString:@""]];
	}
	return self;
}

- (BOOL)webView:(UIWebView *)webView2 
shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType {
    
	NSString *requestString = [[request URL] absoluteString];
    
    //NSLog(@"request : %@",requestString);
    
    if ([requestString hasPrefix:@"link:"]) {
        NSLog(@"should open link: %@", [requestString substringFromIndex:[@"link:" length]]);
        NSString *escaped = [[requestString substringFromIndex:[@"link:" length]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:escaped]];  
        return NO;
    }
    
    return NO;
}

- (void)dealloc
{
    NSLog(@"kthxbai :[");
    [stringToDraw release];
    [super dealloc];
}
#define RENDER_WITH_OPTS \
        if (!([ms string] && ms)) {\
            return;\
        }\
        cstr = [NSString stringWithFormat:@"addToMessage('%@','%@','%@','%@','%@','%@','%@', 'YES');", name, isBold ? @"YES" : @"NO", isUnderline ? @"YES" : @"NO", isItalic ? @"YES" : @"NO", bgcolor, fgcolor, [istring substringWithRange:NSMakeRange(lpos, cpos-lpos)]]; \
        if (![[self stringByEvaluatingJavaScriptFromString:cstr] isEqualToString:@"SUCCESS"]) { \
            NSLog(@"Could not exec: %@", cstr); \
        } else if ([ms  shouldColor]) { \
            [[(RCChannel*)[[self chatpanel] channel] bubble] setMentioned:[ms  highlight]];\
            [[(RCChannel*)[[self chatpanel] channel] bubble] setHasNewMessage:![ms  highlight]];\
        }\
        lpos = cpos;    
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    @synchronized(self)
    {
        NSMutableArray* pre_pool = preloadPool;
        preloadPool = nil;
        for (RCMessageFormatter* ms in pre_pool) {
            [self layoutMessage:ms];
        }
        [pre_pool release];
    }
    NSLog(@"DOM INIT");
}
- (void)layoutMessage:(RCMessageFormatter *)ms {
_out_:
    @synchronized(self)
    {
        if(preloadPool)
        {
            NSLog(@"DOM not ready! Queueing.");
            [preloadPool addObject:ms];
            return;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSString* isReady = [self stringByEvaluatingJavaScriptFromString:@"isReady();"];
        if (![isReady isEqualToString:@"YES"]) {
            
        }
        NSString* name = [self stringByEvaluatingJavaScriptFromString:@"createMessage();"];
        if ([[ms string] hasSuffix:@"\n"]) {
            [ms setString:[[ms string] substringWithRange:NSMakeRange(0, [[ms string] length]-1)]];
        }
        [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setFlags('%@','%@');", name, [[ms string] substringToIndex:[[ms string] rangeOfString:@"-"].location]]];
        NSString* istring = [[[[[[ms string] substringFromIndex:[[ms string] rangeOfString:@"-"].location+1] stringByEncodingHTMLEntities:YES] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"] stringByLinkifyingURLs] stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
        unsigned int cpos = 0;
        BOOL isBold = NO;
        BOOL isItalic = NO;
        BOOL isUnderline = NO;
        NSString* fgcolor = colorForIRCColor(-1);
        NSString* bgcolor = colorForIRCColor(-2);
        unsigned int lpos = 0;
        NSString* cstr;
        NSLog(@"%@", istring);
        while (cpos - [istring length]) {
            switch ([istring characterAtIndex:cpos]) {
                case RCIRCAttributeBold:
                    RENDER_WITH_OPTS;
                    cpos++;
                    isBold = !isBold;
                    lpos = cpos;
                    break;
                case RCIRCAttributeItalic:;;
                    RENDER_WITH_OPTS;
                    cpos++;
                    isItalic = !isItalic;
                    lpos = cpos;
                    break;
                case RCIRCAttributeUnderline:;;
                    RENDER_WITH_OPTS;
                    cpos++;
                    isUnderline = !isUnderline;
                    lpos = cpos;
                    break;
                case RCIRCAttributeReset:;;
                    RENDER_WITH_OPTS;
                    cpos++;
                    fgcolor = colorForIRCColor(-1);
                    bgcolor = colorForIRCColor(-2);
                    isBold = NO;
                    isItalic = NO;
                    isUnderline = NO;
                    lpos = cpos;
                    break;
                case RCIRCAttributeColor:;;
                    RENDER_WITH_OPTS;
                    cpos++;
                    int number1 = -1;
                    int number2 = -2;
                    BOOL itc = YES;
                    if (readNumber(&number1, &itc, &cpos, istring) && itc) {
                        NSLog(@"comma!");
                        itc = NO;
                        readNumber(&number2, &itc, &cpos, istring);
                    } 
                    NSLog(@"Using %d and %d (%d,%d) [%@]", number1, number2, cpos, lpos, [istring substringFromIndex:cpos]);
                    // BOOL readNumber(int* num, BOOL* isThereComma, int* size_of_num, char* data, int size);
                    fgcolor = colorForIRCColor(number1);
                    bgcolor = colorForIRCColor(number2);
                    lpos = cpos;
                    break;
                default:
                    cpos++;
                    continue;
                    break;
            }
            continue;
        }
    skcolor:
        RENDER_WITH_OPTS;
        //NSString* cstr = [NSString stringWithFormat:@"addToMessage('%@','NO','NO','NO','white','black','%@', 'YES');", name, ];
    });
}

- (void)scrollToBottom {
    [self stringByEvaluatingJavaScriptFromString:@"scrollToBottom();"];
    // lalala 
}

/*
 
 - (void)resetContentSize {
 dispatch_async(scrollViewMessageQueue, ^()
 {
 @synchronized(self)
 {
 if (!stringToDraw) return;
 CGFloat kEndPos = self.contentSize.height; 
 CGFloat kCurPos = self.contentOffset.y + self.frame.size.height;
 kEndPos = (kEndPos > self.frame.size.height) ? kEndPos : self.frame.size.height;
 CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)stringToDraw);
 CFRange destRange = CFRangeMake(0, 0);
 CFRange sourceRange = CFRangeMake(0, stringToDraw.length);
 CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, sourceRange, NULL, CGSizeMake(self.frame.size.width, CGFLOAT_MAX), &destRange);
 dispatch_async(dispatch_get_main_queue(), ^()
 {
 self.contentSize = CGSizeMake(self.bounds.size.width, frameSize.height);
 if (kEndPos <= kCurPos)
 [self scrollToBottom];
 [self setNeedsDisplay];
 });
 CFRelease(framesetter);
 }
 });
 }
 
 - (void)scrollViewDidScroll:(UIScrollView *)scrollView {
 shouldScroll = NO;
 //MARK;	
 }
 
 - (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
 //MARK;
 }
 
 - (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
 //MARK;
 }
 
 - (void) drawRect:(CGRect)rect {
 @synchronized(self)
 {
 if (!stringToDraw) return;
 CGContextRef context = UIGraphicsGetCurrentContext();
 
 // Flip the context
 CGContextSetShadowWithColor(context, CGSizeMake(0, 1.0), 0, [UIColor colorWithWhite:0 alpha:0.5].CGColor);
 CGContextSetTextMatrix(context, CGAffineTransformIdentity);
 CGContextTranslateCTM(context, 0, self.contentSize.height);
 CGContextScaleCTM(context, 1.0, -1.0);
 
 CGMutablePathRef path = CGPathCreateMutable();
 CGRect destRect = (CGRect){.size = self.contentSize};
 CGPathAddRect(path, NULL, destRect);
 
 // Create framesetter
 CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)stringToDraw);
 
 // Draw the text
 CTFrameRef theFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, stringToDraw.length), path, NULL);
 if (!theFrame) {
 return;
 }
 CTFrameDraw(theFrame, context);
 
 // Clean up
 CFRelease(path);
 CFRelease(theFrame); // I KNOW RIGHT YOU FUCKER
 CFRelease(framesetter);
 [super drawRect:rect];
 }
 }
 */
@end
