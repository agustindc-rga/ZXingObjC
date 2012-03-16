#import "AbstractNDEFResultParser.h"
#import "NDEFRecord.h"

int const SUPPORTED_HEADER_MASK = 0x3F;
int const SUPPORTED_HEADER = 0x11;
NSString * const TEXT_WELL_KNOWN_TYPE = @"T";
NSString * const URI_WELL_KNOWN_TYPE = @"U";
NSString * const SMART_POSTER_WELL_KNOWN_TYPE = @"Sp";
NSString * const ACTION_WELL_KNOWN_TYPE = @"act";

@implementation NDEFRecord

@synthesize type, payload, payloadLength, totalRecordLength;

- (id) initWithHeader:(int)aHeader type:(NSString *)aType payload:(unsigned char *)aPayload payloadLength:(unsigned int)aPayloadLength totalRecordLength:(unsigned int)aTotalRecordLength {
  if (self = [super init]) {
    header = aHeader;
    type = [aType copy];
    payload = aPayload;
    payloadLength = aPayloadLength;
    totalRecordLength = aTotalRecordLength;
  }
  return self;
}

+ (NDEFRecord *) readRecord:(unsigned char *)bytes offset:(int)offset {
  int header = bytes[offset] & 0xFF;
  if (((header ^ SUPPORTED_HEADER) & SUPPORTED_HEADER_MASK) != 0) {
    return nil;
  }
  int typeLength = bytes[offset + 1] & 0xFF;
  
  unsigned int payloadLength = bytes[offset + 2] & 0xFF;

  NSString * type = [AbstractNDEFResultParser bytesToString:bytes offset:offset + 3 length:typeLength encoding:NSASCIIStringEncoding];

  unsigned char payload[payloadLength];
  int payloadCount = 0;
  for (int i = offset + 3 + typeLength; i < offset + 3 + typeLength + payloadLength; i++) {
    payload[payloadCount++] = bytes[i];
  }

  return [[[NDEFRecord alloc] initWithHeader:header type:type payload:payload payloadLength:payloadLength totalRecordLength:3 + typeLength + payloadLength] autorelease];
}

- (BOOL) messageBegin {
  return (header & 0x80) != 0;
}

- (BOOL) messageEnd {
  return (header & 0x40) != 0;
}

- (void) dealloc {
  //free(payload);
  [type release];
  [super dealloc];
}

@end
