//
//  RCTableView.h
//  Relay
//
//  Created by Max Shavrick on 3/8/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface RCTableView : UITableView {
	UIImageView *bottomShadow;
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style;

@end