//
//  RCUserTableCell.m
//  Relay
//
//  Created by Max Shavrick on 3/15/12.
//

#import "RCUserTableCell.h"
#import "RCChatController.h"
#import "NSString+IRCStringSupport.h"
#import "RCPMChannel.h"

@implementation RCUserTableCell
@synthesize isLast, isWhois, contentView, channel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		contentView = [[RCUserTableCellContentView alloc] initWithFrame:CGRectZero];
		[self addSubview:contentView];
		[contentView release];
		[self.textLabel retain];
		[self.textLabel removeFromSuperview];
		[contentView addSubview:self.textLabel];
		[self.textLabel release];
		self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
		self.textLabel.textColor = [UIColor colorWithRed:204/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f];
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		isWhois = NO;
		fakeSelected = NO;
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];
	[self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
	contentView->fakeSelected = YES;
	[contentView setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
	contentView->fakeSelected = NO;
	[contentView setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	contentView->fakeSelected = NO;
	[contentView setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	self.textLabel.hidden = isWhois;
	[contentView setNeedsDisplay];
}

@end
