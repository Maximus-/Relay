//
//  RCAttribute.h
//  Relay
//
//  Created by Max Shavrick on 7/27/14.
//

#import <Foundation/Foundation.h>

typedef enum RCIRCAttribute {
	RCIRCAttributeColor = 0x03,
	RCIRCAttributeBold = 0x02,
	RCIRCAttributeReset = 0x0F,
	RCIRCAttributeItalic = 0x16,
	RCIRCAttributeUnderline = 0x1F,
	RCIRCAttributeInternalNickname = 0x04
} RCIRCAttribute;

@interface RCAttribute : NSObject {
	RCIRCAttribute _type;
	int _start, _end;
}
@property (nonatomic, readonly) int start;
@property (nonatomic, assign) int end;
@property (nonatomic, readonly) RCIRCAttribute type;
- (id)initWithType:(RCIRCAttribute)typ start:(int)pos;
@end
