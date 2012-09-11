//
//  NSString+Comparing.m
//  Relay
//
//  Created by Max Shavrick on 2/19/12.
//  Copyright (c) 2012 American Heritage School. All rights reserved.
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

- (BOOL)isEqualToStringNoCase:(NSString *)string {
	return [[self lowercaseString] isEqualToString:[string lowercaseString]];
}

- (BOOL)hasPrefixNoCase:(NSString *)string {
	return [[self lowercaseString] hasPrefix:[string lowercaseString]];
}

- (BOOL)hasSuffixNoCase:(NSString *)string {
	return [[self lowercaseString] hasSuffix:[string lowercaseString]];
}

- (NSString *)recursivelyRemovePrefix:(NSString *)prefix {
	if (!prefix || !self) return nil;
	if ([self hasPrefix:prefix])
		self = [self substringFromIndex:[prefix length]];
	else return self;
	return [self recursivelyRemovePrefix:prefix];
}


@end
