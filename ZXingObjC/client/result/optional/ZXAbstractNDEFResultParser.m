#import "ZXAbstractNDEFResultParser.h"

@implementation ZXAbstractNDEFResultParser

+ (NSString *)bytesToString:(unsigned char *)bytes offset:(int)offset length:(unsigned int)length encoding:(NSStringEncoding)encoding { 
  return [[[NSString alloc] initWithBytes:bytes + offset length:length encoding:encoding] autorelease];
}

@end
